//
//  BCViewController.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//

import Cocoa
import Alamofire
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


class BCViewController: NSViewController, NSWindowDelegate {
    
    /// The main window of this view controller
    var window : NSWindow = NSWindow();
    
    /// The  controller for browsing boorus in Grid|Image mode
    @IBOutlet var gridStyleController: BCGridStyleController!
    
    /// The visual effect view for the window's background
    @IBOutlet var backgroundVisualEffectView: NSVisualEffectView!
    
    /// The booru choosing popup for the toolbar of this browser
    weak var toolbarBooruPopup : NSPopUpButton!
    
    /// When we select an item in `toolbarBooruPopup`...
    @IBAction func toolbarBooruPopupItemSelected(_ sender: AnyObject) {
        // Update the searching Booru
        updateSelectedSearchingBooru();
    }
    
    /// The search field for the toolbar of this browser
    weak var toolbarSearchField : BCBooruSearchTokenField!
    
    /// When the user enters text into `toolbarSearchField`...
    @IBAction func toolbarSearchFieldTextEntered(_ sender: BCBooruSearchTokenField) {
        // Search for the entered text(It replaces commas with spaces because when NSTokenField gives you it's stringValue, there is a comma in between each token)
        gridStyleController.searchFor(sender.stringValue.replacingOccurrences(of: ",", with: " "));
        
        // Add all the searched tags to the current Booru's history
        // For every entered token...
        for(_, currentToken) in sender.tokens.enumerated() {
            // Add the current token to the search history of the current Searching Booru
            currentSelectedSearchingBooru?.addTagToHistory(currentToken);
        }
    }
    
    /// The current Booru the user selected to search from
    var currentSelectedSearchingBooru : BCBooruHost? = nil;
    
    /// The log of copied post URLs
    var postUrlCopyLog : [String] = [];
    
    /// The log of copied image URLs
    var imageUrlCopyLog : [String] = [];
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Tell BCAppDelegate to load the preferences
        (NSApplication.shared().delegate as! BCAppDelegate).loadPreferences();
        
        // Style the window
        styleWindow();
        
        // Add the preferences updated observer
        NotificationCenter.default.addObserver(self, selector: #selector(BCViewController.preferencesUpdated), name: NSNotification.Name(rawValue: "BCPreferences.Updated"), object: nil);
        
        // Initialize everything
        gridStyleController.initialize();
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear();
        
        // Restore the window frame from autosave
        self.window.setFrameUsingName(self.window.frameAutosaveName);
        
        // Get all the toolbar items
        for(_, currentItem) in self.window.toolbar!.items.enumerated() {
            switch(currentItem.itemIdentifier) {
            case "BooruSelector":
                self.toolbarBooruPopup = (currentItem.view as! NSPopUpButton);
                break;
                
            case "SearchField":
                self.toolbarSearchField = (currentItem.view as! BCBooruSearchTokenField);
                break;
                
            default:
                break;
            }
        }
        
        // Set the target and action for the toolbar search field's tokens changed event
        toolbarSearchField.tokensChangedTarget = self;
        toolbarSearchField.tokensChangedAction = #selector(BCViewController.searchTokensChanged);
        
        // Update the Booru picker popup button
        updateBooruPickerPopupButton();
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear();
        
        // Save the window frame
        self.window.saveFrame(usingName: self.window.frameAutosaveName);
        UserDefaults.standard.synchronize();
    }
    
    /// Called when the tokens from toolbarSearchField change
    func searchTokensChanged() {
        // Update the tag display list
        gridStyleController.tagListController.displayTagsFromPost(gridStyleController.tagListController.lastDisplayedPost);
    }
    
    /// Called when the preferences are updated
    func preferencesUpdated() {
        /// The index of the item to select after the Boorus are updated
        var selectionIndex : Int = 0;
        
        // If the selection item isnt nil...
        if(toolbarBooruPopup.selectedItem != nil) {
            // Set selection index to the index of the selected item
            selectionIndex = toolbarBooruPopup.index(of: toolbarBooruPopup.selectedItem!);
        }
        
        // Update the Searching Boorus
        updateBooruPickerPopupButton();
        
        // Reselect the previous item
        toolbarBooruPopup.selectItem(at: selectionIndex);
        
        // If the selected item is now nil...
        if(toolbarBooruPopup.selectedItem == nil) {
            // Select the last item in toolbarBooruPopup
            toolbarBooruPopup.selectItem(at: toolbarBooruPopup.index(of: toolbarBooruPopup.lastItem!));
        }
    }
    
    /// Saves the given BCBooruCollectionViewItems
    func saveBooruItems(_ items : [BCBooruCollectionViewItem]) {
        // If there is at least one item in items...
        if(items.count > 0) {
            /// The save panel to get the directory to save the images to
            let saveDirectorySavePanel : NSSavePanel = NSSavePanel();
            
            // Set the name field default value to the image save format
            saveDirectorySavePanel.nameFieldStringValue = (NSApplication.shared().delegate as! BCAppDelegate).preferences.imageSaveFormat;
            
            // Set the prompt to "Save"
            saveDirectorySavePanel.prompt = "Save";
            
            // Run the open panel, and if the user hits "Save"...
            if(Bool(saveDirectorySavePanel.runModal() as NSNumber)) {
                /// The directory we are saving the images to
                var saveDirectory : String = saveDirectorySavePanel.url!.absoluteString.removingPercentEncoding!.replacingOccurrences(of: "file://", with: "");
                
                // Set saveDirectory to the folder of saveDirectory
                saveDirectory = String(NSString(string: saveDirectory).deletingLastPathComponent) + "/";
                
                /// The items to download from items
                var downloadItems : [BCBooruCollectionViewItem] = [];
                
                // For every item in items...
                for(_, currentItem) in items.enumerated() {
                    // If the current item isn't a "No More Results" item...
                    if(!currentItem.noMoreResultsItem) {
                        // Append the current item to downloadItems
                        downloadItems.append(currentItem);
                    }
                }
                
                // If downloadItems isn't empty...
                if(downloadItems.count > 0) {
                    // Print how many images we are saving and where
                    print("BCViewController: Saving \(items.count) image(s) to \"\(saveDirectory)\"");
                    
                    // Download the items
                    self.downloadBooruItems(downloadItems, saveDirectory: saveDirectory, tags: toolbarSearchField.stringValue, count: downloadItems.count, filenameFormat: saveDirectorySavePanel.nameFieldStringValue, fileTags: (saveDirectorySavePanel.tagNames == nil) ? [] : saveDirectorySavePanel.tagNames!);
                }
            }
        }
        // If items is blank...
        else {
            // Print that there were no passed items to save
            print("BCViewController: Cant save empty array of BCBooruCollectionViewItems");
        }
    }
    
    /// The actual downloading part of saveBooruItems, saves the given items to the given path, uses tags and count when showing the download completed notification. filenameFormat is used as the format for the saved file's name, and fileTags are the tags that should be added to the saved files
    private func downloadBooruItems(_ items : [BCBooruCollectionViewItem], saveDirectory : String, tags : String, count : Int, filenameFormat : String, fileTags : [String]) -> Void {
        var items = items
        if let currentSaveItem = items.popLast() {
            // Print what image we are saving
            print("BCViewController: Saving \(currentSaveItem.representedPost!.imageUrl)");
            
            /// The name of the image file
            var imageFileName : String = filenameFormat;
            
            // Replace %id% with the image's id
            imageFileName = imageFileName.replacingOccurrences(of: "%id%", with: String(currentSaveItem.representedPost!.id));
            
            // Replace %booru% with the post's Booru's name
            imageFileName = imageFileName.replacingOccurrences(of: "%booru%", with: String(currentSelectedSearchingBooru!.name));
            
            /// Every tag of this post(With spaces in between) put into a string
            var tagsString : String = "";
            
            // For every tag on this post...
            for(_, currentTag) in currentSaveItem.representedPost!.tags.enumerated() {
                // Add the current tag to tagsString
                tagsString += currentTag + " ";
            }
            
            // If tagsString isnt blank...
            if(tagsString != "") {
                // Remove the trailing space that was added from adding the tags
                tagsString = tagsString.substring(to: tagsString.characters.index(before: tagsString.endIndex));
            }
            
            // Replace %tags% with the tags string
            imageFileName = imageFileName.replacingOccurrences(of: "%tags%", with: tagsString);
            
            // If we have already downloaded the image...
            if(currentSaveItem.finishedLoadingImage) {
                // Save the image asynchronously so it doesn't lag the interface
                DispatchQueue.global(qos: DispatchQoS.default.qosClass).async {
                    // Replace %md5% with the MD5 hash of this image
                    imageFileName = imageFileName.replacingOccurrences(of: "%md5%", with: currentSaveItem.image.MD5()!);
                    
                    // Remove all /'s in the file name
                    imageFileName = imageFileName.replacingOccurrences(of: "/", with: " ");
                    
                    // If imageFileName has over 250 characters...
                    if(imageFileName.characters.count > 250) {
                        // Cut imageFileName down to 250 characters
                        imageFileName = imageFileName.substring(to: imageFileName.characters.index(imageFileName.startIndex, offsetBy: 250));
                        
                        /// The indexes of all the spaces in imageFileName
                        let indexesOfSpaceInImageFileName = imageFileName.characters.enumerated()
                            .filter { $0.element == " " }
                            .map { $0.offset }
                        
                        // Cut imageFileName down to the last space
                        imageFileName = imageFileName.substring(to: imageFileName.characters.index(imageFileName.startIndex, offsetBy: indexesOfSpaceInImageFileName.last!));
                    }
                    
                    // Add the extension onto the end
                    imageFileName += "." + NSString(string: currentSaveItem.representedPost!.imageUrl).pathExtension;
                    
                    // Write the image to the chosen directory with the generated file name
                    currentSaveItem.image.saveTo(saveDirectory + imageFileName, fileType: BCImageUtilities().fileTypeFromExtension((NSString(string: currentSaveItem.representedPost!.imageUrl).pathExtension))!);
                    
                    // Add the file tags
                    let fileUrl : NSURL = NSURL(fileURLWithPath: saveDirectory + imageFileName);
                    
                    do {
                        try fileUrl.setResourceValue(fileTags as AnyObject?, forKey: URLResourceKey.tagNamesKey);
                    }
                    catch let error as NSError {
                        print("BCViewController: Error setting tags for \"\(saveDirectory + imageFileName)\", \(error.description)");
                    }
                    
                    // Print that we saved the image
                    print("BCViewController: Saved image to \"\(saveDirectory + imageFileName)\"");
                }
                
                // Save the image to disk, asynchronously
                DispatchQueue.main.async {
                    // Add the ID of this post to the current searching Booru's downloaded posts
                    self.currentSelectedSearchingBooru?.addIDToDownloadHistory(currentSaveItem.representedPost!.id);
                    
                    // Download the next item
                    self.downloadBooruItems(items, saveDirectory: saveDirectory, tags: tags, count: count, filenameFormat: filenameFormat, fileTags: fileTags);
                }
            }
            // If we have to download the image...
            else {
                // Download the post item's full size image
                Alamofire.request(currentSaveItem.representedPost!.imageUrl)
                    .responseData { response in
                        // If data isnt nil...
                        if let data = response.result.value {
                            /// The downloaded image
                            let image : NSImage? = NSImage(data: data);
                            
                            // If image isnt nil...
                            if(image != nil) {
                                // Store the image in the post item
                                currentSaveItem.image = image!;
                                
                                // Save the image asynchronously so it doesn't lag the interface
                                DispatchQueue.global().async {
                                    // Replace %md5% with the MD5 hash of this image
                                    imageFileName = imageFileName.replacingOccurrences(of: "%md5%", with: currentSaveItem.image.MD5()!);
                                    
                                    // Remove all /'s in the file name
                                    imageFileName = imageFileName.replacingOccurrences(of: "/", with: " ");
                                    
                                    // If imageFileName has over 250 characters...
                                    if(imageFileName.characters.count > 250) {
                                        // Cut imageFileName down to 250 characters
                                        imageFileName = imageFileName.substring(to: imageFileName.characters.index(imageFileName.startIndex, offsetBy: 250));
                                        
                                        /// The indexes of all the spaces in imageFileName
                                        let indexesOfSpaceInImageFileName = imageFileName.characters.enumerated()
                                            .filter { $0.element == " " }
                                            .map { $0.offset }
                                        
                                        // Cut imageFileName down to the last space
                                        imageFileName = imageFileName.substring(to: imageFileName.characters.index(imageFileName.startIndex, offsetBy: indexesOfSpaceInImageFileName.last!));
                                    }
                                    
                                    // Add the extension onto the end
                                    imageFileName += "." + NSString(string: currentSaveItem.representedPost!.imageUrl).pathExtension;
                                    
                                    // Write the image to the chosen directory with the generated file name
                                    currentSaveItem.image.saveTo(saveDirectory + imageFileName, fileType: BCImageUtilities().fileTypeFromExtension((NSString(string: currentSaveItem.representedPost!.imageUrl).pathExtension))!);
                                    
                                    // Add the file tags
                                    let fileUrl : NSURL = NSURL(fileURLWithPath: saveDirectory + imageFileName);
                                    
                                    do {
                                        try fileUrl.setResourceValue(fileTags as AnyObject?, forKey: URLResourceKey.tagNamesKey);
                                    }
                                    catch let error as NSError {
                                        print("BCViewController: Error setting tags for \"\(saveDirectory + imageFileName)\", \(error.description)");
                                    }
                                    
                                    // Print that we saved the image
                                    print("BCViewController: Saved image to \"\(saveDirectory + imageFileName)\"");
                                }
                                
                                // Dispatch onto the main queue
                                DispatchQueue.main.async {
                                    // Add the ID of this post to the current searching Booru's downloaded posts
                                    self.currentSelectedSearchingBooru?.addIDToDownloadHistory(currentSaveItem.representedPost!.id);
                                    
                                    // Download the next item
                                    self.downloadBooruItems(items, saveDirectory: saveDirectory, tags: tags, count: count, filenameFormat: filenameFormat, fileTags: fileTags);
                                }
                            }
                        }
                };
            }
        }
        else {
            // Reload the downloaded indicators for the grid style controller
            self.gridStyleController.reloadDownloadedIndicators();
            
            // If the user has downloads finished notifications on and we downloaded more than one image...
            if((NSApplication.shared().delegate as! BCAppDelegate).preferences.notifyWhenDownloadsFinished && count > 1) {
                /// The notification to tell the user that tells the user their downloads have finished
                let downloadsFinishedNotification : NSUserNotification = NSUserNotification();
                
                // Set the informative text
                downloadsFinishedNotification.informativeText = "\(count) images downloaded";
                
                // Post the notification
                NSUserNotificationCenter.default.deliver(downloadsFinishedNotification);
            }
        }
    }
    
    /// Saves the selected Booru post images
    func saveSelectedImages() {
        // Save the selected items
        saveBooruItems(gridStyleController.getSelectedBooruItems());
    }
    
    /// Opens the selected posts in the browser
    func openSelectedPostsInBrowser() {
        // For every selected post...
        for(_, currentSelectedPost) in gridStyleController.getSelectedBooruItems().enumerated() {
            // Open the selected post in the browser
            NSWorkspace.shared().open(URL(string: currentSelectedPost.representedPost!.url)!);
        }
    }
    
    /// Copys the URLs of the selected posts
    func copyUrlsOfSelectedPosts() {
        /// The string to copy to the pasteboard
        var copyString : String = "";
        
        // For every selected post...
        for(currentIndex, currentSelectedPost) in gridStyleController.getSelectedBooruItems().enumerated() {
            // If this isnt the last item...
            if(currentIndex != (gridStyleController.getSelectedBooruItems().count - 1)) {
                // Add the current item's post's URL to the end of copyString, with a trailing new line
                copyString += currentSelectedPost.representedPost!.url + "\n";
            }
            // If ths is the last item...
            else {
                // Add the current item's post's URL to the end of copyString
                copyString += currentSelectedPost.representedPost!.url;
            }
            
            // If the current post's URL isnt already in postUrlCopyLog...
            if(!postUrlCopyLog.contains(currentSelectedPost.representedPost!.url)) {
                // Add the current post's URL to postUrlCopyLog
                postUrlCopyLog.append(currentSelectedPost.representedPost!.url);
            }
        }
        
        // Copy copyString
        // Add the string type to the general pasteboard
        NSPasteboard.general().declareTypes([NSStringPboardType], owner: nil);
        
        // Set the string of the general pasteboard to copyString
        NSPasteboard.general().setString(copyString, forType: NSStringPboardType);
    }
    
    /// Copies all the URLs in postUrlCopyLog
    func copyPreviouslyCopiedPostUrls() {
        /// The string to copy
        var copyString : String = "";
        
        // For every item in postUrlCopyLog...
        for(_, currentUrl) in postUrlCopyLog.enumerated() {
            // Add the current URL to the end of copyString, with a trailing new line
            copyString += currentUrl + "\n";
        }
        
        // If copyString isnt empty...
        if(copyString != "") {
            // Remove the final new line from copyString
            copyString = copyString.substring(to: copyString.characters.index(before: copyString.endIndex));
        }
        
        // Copy copyString
        // Add the string type to the general pasteboard
        NSPasteboard.general().declareTypes([NSStringPboardType], owner: nil);
        
        // Set the string of the general pasteboard to copyString
        NSPasteboard.general().setString(copyString, forType: NSStringPboardType);
    }
    
    /// Copys the image URLs of the selected posts
    func copyImageUrlsOfSelectedPosts() {
        /// The string to copy to the pasteboard
        var copyString : String = "";
        
        // For every selected post...
        for(currentIndex, currentSelectedPost) in gridStyleController.getSelectedBooruItems().enumerated() {
            // If this isnt the last item...
            if(currentIndex != (gridStyleController.getSelectedBooruItems().count - 1)) {
                // Add the current item's post's image URL to the end of copyString, with a trailing new line
                copyString += currentSelectedPost.representedPost!.imageUrl + "\n";
            }
                // If ths is the last item...
            else {
                // Add the current item's post's image URL to the end of copyString
                copyString += currentSelectedPost.representedPost!.imageUrl;
            }
            
            // If the current post's image URL isnt already in imageUrlCopyLog...
            if(!imageUrlCopyLog.contains(currentSelectedPost.representedPost!.imageUrl)) {
                // Add the current post's image URL to imageUrlCopyLog
                imageUrlCopyLog.append(currentSelectedPost.representedPost!.imageUrl);
            }
        }
        
        // Copy copyString
        // Add the string type to the general pasteboard
        NSPasteboard.general().declareTypes([NSStringPboardType], owner: nil);
        
        // Set the string of the general pasteboard to copyString
        NSPasteboard.general().setString(copyString, forType: NSStringPboardType);
    }
    
    /// Copies all the URLs in imageUrlCopyLog
    func copyPreviouslyCopiedImageUrls() {
        /// The string to copy
        var copyString : String = "";
        
        // For every item in imageUrlCopyLog...
        for(_, currentUrl) in imageUrlCopyLog.enumerated() {
            // Add the current URL to the end of copyString, with a trailing new line
            copyString += currentUrl + "\n";
        }
        
        // If copyString isnt empty...
        if(copyString != "") {
            // Remove the final new line from copyString
            copyString = copyString.substring(to: copyString.characters.index(before: copyString.endIndex));
        }
        
        // Copy copyString
        // Add the string type to the general pasteboard
        NSPasteboard.general().declareTypes([NSStringPboardType], owner: nil);
        
        // Set the string of the general pasteboard to copyString
        NSPasteboard.general().setString(copyString, forType: NSStringPboardType);
    }
    
    /// Updates currentSelectedSearchingBooru to match the selected item in toolbarBooruPopup
    func updateSelectedSearchingBooru() {
        // Clear the current searching Booru's last search
        currentSelectedSearchingBooru?.utilties?.lastSearch = "";
        
        // If there isnt one item with a title of "No Boorus Added" in toolbarBooruPopup...
        if(toolbarBooruPopup.itemArray.count != 1 && toolbarBooruPopup.itemArray[0].title != "No Boorus Added") {
            // Set the selected searching Booru to the selected Booru
            currentSelectedSearchingBooru = (NSApplication.shared().delegate as! BCAppDelegate).preferences.booruHosts[toolbarBooruPopup.index(of: toolbarBooruPopup.selectedItem!)];
        }
        else {
            // Set currentSelectedSearchingBooru to nil
            currentSelectedSearchingBooru = nil;
        }
        
        // If currentSelectedSearchingBooru isnt nil...
        if(currentSelectedSearchingBooru != nil) {
            // Print what the new searching Booru is
            print("BCViewController: Changed searching Booru to \(currentSelectedSearchingBooru!.name)");
        }
        // If currentSelectedSearchingBooru is nil...
        else {
            // Print that the user has no Boorus added
            print("BCViewController: Tried to change searching Boorus, but the user doesnt have any");
        }
        
        // Set the search field's token Booru
        toolbarSearchField.tokenBooru = currentSelectedSearchingBooru;
    }
    
    /// Updates toolbarBooruPopup to match the Boorus listed in the user's added Boorus
    func updateBooruPickerPopupButton() {
        // Clear all the current items in toolbarBooruPopup
        toolbarBooruPopup.removeAllItems();
        
        // For every Booru in the user's Boorus...
        for(_, currentBooruHost) in (NSApplication.shared().delegate as! BCAppDelegate).preferences.booruHosts.enumerated() {
            // Add the current item to toolbarBooruPopup
            toolbarBooruPopup.addItem(withTitle: currentBooruHost.name);
        }
        
        // If there arent any items in toolbarBooruPopup...
        if(toolbarBooruPopup.menu?.items.count < 1) {
            // Add an item saying "No Boorus Added" to toolbarBooruPopup
            toolbarBooruPopup.addItem(withTitle: "");
        }
        
        // Update the searching Booru
        updateSelectedSearchingBooru();
    }
    
    /// Is the titlebar visible?
    var titlebarVisible : Bool = true;
    
    /// Toggles the visibility of the titlebar
    func toggleTitlebar() {
        // Toggle titlebarVisible
        titlebarVisible = !titlebarVisible;
        
        // If blank is now visible...
        if(titlebarVisible) {
            // Show the titlebar
            showTitlebar();
        }
        // If the titlebar is now hidden...
        else {
            // Hide the titlebar
            hideTitlebar();
        }
    }
    
    /// Hides the titlebar
    func hideTitlebar() {
        // If we arent in fullscreen...
        if(!(window.styleMask.contains(NSFullScreenWindowMask))) {
            // Hide the OSX titlebar
            window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = true;
        }
        
        // Redraw the window's content view so we dont get odd vibrancy artifacts
        window.contentView?.needsDisplay = true;
    }
    
    /// Shows the titlebar
    func showTitlebar() {
        // Show the OSX titlebar
        window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = false;
        
        // Redraw the window's content view so we dont get odd vibrancy artifacts
        window.contentView?.needsDisplay = true;
    }
    
    /// Makes the post browser the first responder
    func selectPostBrowser() {
        // Make booruCollectionView the first responder
        window.makeFirstResponder(gridStyleController.booruCollectionView);
    }
    
    /// Opens the popup for toolbarBooruPopup
    func openBooruPopup() {
        toolbarBooruPopup.performClick(self);
    }
    
    /// Makes toolbarSearchField the first responder
    func selectSearchField() {
        // Make toolbarSearchField the first responder
        window.makeFirstResponder(toolbarSearchField);
    }
    
    func windowShouldClose(_ sender: Any) -> Bool {
        // Deinit
        self.gridStyleController.booruCollectionViewArrayController.remove(self);
        
        return true;
    }
    
    /// Styles the window
    func styleWindow() {
        // Get the window
        window = NSApplication.shared().windows.last!;
        
        // Tell the window controller not to cascade so positions can be restored
        window.windowController!.shouldCascadeWindows = false;
        
        // Restore the window's autosave name
        window.setFrameAutosaveName("BooruChanBrowser");
        
        // Set the window's delegate
        window.delegate = self;
        
        // Set the window's appearance
        window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark);
        
        // Style the titlebar
        window.titleVisibility = .hidden;
        window.styleMask.insert(NSFullSizeContentViewWindowMask);
        window.toolbar?.showsBaselineSeparator = false;
        
        // Set the visual effects views' materials
        backgroundVisualEffectView.material = .dark;
    }
}
