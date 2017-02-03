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
    
    /// The constraint for the top of gridStyleController.imageViewScrollView
    private var imageViewScrollViewTopConstraint : NSLayoutConstraint? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        (NSApplication.shared().delegate as! BCAppDelegate).loadPreferences();
        NotificationCenter.default.addObserver(self, selector: #selector(BCViewController.preferencesUpdated), name: NSNotification.Name(rawValue: "BCPreferences.Updated"), object: nil);
        
        initialize();
        gridStyleController.initialize();
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
        
        // Add the constraint for the top of the image view so it centers relative to the visible frame, not the whole window
        createImageViewScrollViewConstraints(relativeTo: window.standardWindowButton(.closeButton)!.superview!.superview!, attribute: .bottom);
        
        updateBooruPickerPopupButton();
        updateTitle();
    }
    
    private func createImageViewScrollViewConstraints(relativeTo : NSView, attribute : NSLayoutAttribute, constant : CGFloat = 0) {
        if(imageViewScrollViewTopConstraint != nil) {
            window.contentView?.superview?.removeConstraint(imageViewScrollViewTopConstraint!);
        }
        
        imageViewScrollViewTopConstraint = NSLayoutConstraint(item: gridStyleController.imageViewScrollView, attribute: .top, relatedBy: .equal, toItem: relativeTo, attribute: attribute, multiplier: 1, constant: constant);
        window.contentView?.superview?.addConstraint(imageViewScrollViewTopConstraint!);
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear();
        
        // Save the window frame
        self.window.saveFrame(usingName: self.window.frameAutosaveName);
        UserDefaults.standard.synchronize();
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        if(!titlebarVisible) {
            showTitlebar();
        }
    }
    
    func windowDidEnterFullScreen(_ notification: Notification) {
        createImageViewScrollViewConstraints(relativeTo: view, attribute: .top, constant: 37);
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        createImageViewScrollViewConstraints(relativeTo: window.standardWindowButton(.closeButton)!.superview!.superview!, attribute: .bottom);
    }
    
    /// Called when the tokens from toolbarSearchField change
    func searchTokensChanged() {
        // Update the tag display list
        gridStyleController.tagListController.displayTagsFromPost(gridStyleController.tagListController.lastDisplayedPost);
    }
    
    /// Called when the preferences are updated
    func preferencesUpdated() {
        // Restore the selected searching booru
        updateBooruPickerPopupButton(updateSearching: false);
        toolbarBooruPopup.selectItem(at: lastPickedBooruIndex);
        updateSelectedSearchingBooru();
        
        applyTheme((NSApp.delegate as! BCAppDelegate).preferences.theme);
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
            print("BCViewController: Changed searching booru to \(currentSelectedSearchingBooru!.name)");
        }
        // If currentSelectedSearchingBooru is nil...
        else {
            // Print that the user has no Boorus added
            print("BCViewController: Tried to change searching boorus, but the user doesnt have any");
        }
        
        // Only update the title if the user hasn't searched for anything yet
        if(gridStyleController.booruCollectionViewArrayControllerItems.count == 0) {
            updateTitle();
        }
        
        // Set the search field's token Booru
        toolbarSearchField.tokenBooru = currentSelectedSearchingBooru;
    }
    
    private var lastPickedBooruIndex : Int = -1;
    
    /// Updates toolbarBooruPopup to match the Boorus listed in the user's added Boorus
    func updateBooruPickerPopupButton(updateSearching : Bool = true) {
        lastPickedBooruIndex = toolbarBooruPopup.indexOfSelectedItem;
        
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
        
        if(updateSearching) {
            updateSelectedSearchingBooru();
        }
    }
    
    private var titlebarVisible : Bool = true;
    
    func toggleTitlebar() {
        titlebarVisible = !titlebarVisible;

        if(titlebarVisible) {
            showTitlebar();
        }
        else {
            hideTitlebar();
        }
    }
    
    func hideTitlebar() {
        if(!window.styleMask.contains(NSFullScreenWindowMask)) {
            window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = true;
        }
        
        gridStyleController.booruCollectionViewScrollView.automaticallyAdjustsContentInsets = false;
        gridStyleController.booruCollectionViewScrollView.contentInsets = NSEdgeInsetsZero;
        createImageViewScrollViewConstraints(relativeTo: window.contentView!, attribute: .top);
        
        window.contentView?.needsDisplay = true;
        
        titlebarVisible = false;
    }
    
    func showTitlebar() {
        window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = false;
        gridStyleController.booruCollectionViewScrollView.automaticallyAdjustsContentInsets = true;
        createImageViewScrollViewConstraints(relativeTo: window.standardWindowButton(.closeButton)!.superview!.superview!, attribute: .bottom);
        
        window.contentView?.needsDisplay = true;
        
        titlebarVisible = true;
    }
    
    func selectPostBrowser() {
        window.makeFirstResponder(gridStyleController.booruCollectionView);
    }
    
    func openBooruPopup() {
        toolbarBooruPopup.performClick(self);
    }
    
    func selectSearchField() {
        window.makeFirstResponder(toolbarSearchField);
    }
    
    func toggleBooruCollectionView() {
        gridStyleController.toggleBooruCollectionView();
    }
    
    func toggleInfoBar() {
        gridStyleController.toggleInfoBar();
    }
    
    func toggleTagList() {
        gridStyleController.toggleTagList();
    }
    
    func zoomIn() {
        gridStyleController.zoomIn();
    }
    
    func zoomOut() {
        gridStyleController.zoomOut();
    }
    
    func resetZoomWithAnimation() {
        gridStyleController.resetZoomWithAnimation();
    }
    
    func windowShouldClose(_ sender: Any) -> Bool {
        gridStyleController.booruCollectionViewArrayController.remove(gridStyleController.booruCollectionViewArrayController.arrangedObjects);
        return true;
    }
    
    func updateTitle() {
        // "tag1 tag2 tag3" - Booru name
        window.title = "\(((toolbarSearchField.stringValue == "") ? "" : "\"\(toolbarSearchField.stringValue)\" - ").replacingOccurrences(of: ",", with: " "))\(currentSelectedSearchingBooru?.name ?? "Booru-chan")";
    }
    
    func initialize() {
        window = NSApplication.shared().windows.last!;
        window.windowController!.shouldCascadeWindows = false;
        window.delegate = self;
        window.styleMask.insert(NSFullSizeContentViewWindowMask);
        window.titleVisibility = .hidden;
        applyTheme((NSApp.delegate as! BCAppDelegate).preferences.theme);
    }
    
    private var currentTheme : BCTheme = .none;
    
    func applyTheme(_ theme : BCTheme) {
        if(theme == currentTheme) { return; }
        currentTheme = theme;
        
        window.appearance = NSAppearance(named: (theme == .dark) ? NSAppearanceNameVibrantDark : NSAppearanceNameVibrantLight);
        window.toolbar?.showsBaselineSeparator = (theme == .light);
        backgroundVisualEffectView.material = (theme == .dark) ? .dark : .selection;
        
        // Redraw the booru collection view(selection box needs to be updated)
        gridStyleController.booruCollectionView.itemPrototype = NSStoryboard(name: "Main", bundle: Bundle.main).instantiateController(withIdentifier: "booruCollectionViewItem") as! BCBooruCollectionViewCollectionViewItem;
    }
}

enum BCTheme: Int {
    case none = -1, dark = 0, light = 1
}
