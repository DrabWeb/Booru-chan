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
    
    /// The visual effect view for the window's titlebar
    @IBOutlet var titlebarVisualEffectView: NSVisualEffectView!
    
    /// The visual effect view for the window's background
    @IBOutlet var backgroundVisualEffectView: NSVisualEffectView!
    
    /// The constraint for the toolbar items for what the minium size of the left container can be
    @IBOutlet var titlebarItemsSplitViewLeftMinimumWidthConstraint: NSLayoutConstraint!
    
    /// The popup button for choosing which Booru to search in
    @IBOutlet var titlebarBooruPickerPopupButton: NSPopUpButton!
    
    /// When we select an item in titlebarBooruPickerPopupButton...
    @IBAction func titlebarBooruPickerPopupButtonItemSelected(_ sender: AnyObject) {
        // Update the searching Booru
        updateSelectedSearchingBooru();
    }
    
    /// The token field in the titlebar for searching
    @IBOutlet var titlebarSearchField: BCBooruSearchTokenField!
    
    /// When the user enters text into titlebarSearchField...
    @IBAction func titlebarSearchFieldTextEntered(_ sender: NSTokenField) {
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
        
        // Setup the menu items
        setupMenuItems();
        
        // Add the preferences updated observer
        NotificationCenter.default.addObserver(self, selector: #selector(BCViewController.preferencesUpdated), name: NSNotification.Name(rawValue: "BCPreferences.Updated"), object: nil);
        
        // Set the target and action for the titlebar search field's tokens changed event
        titlebarSearchField.tokensChangedTarget = self;
        titlebarSearchField.tokensChangedAction = #selector(BCViewController.searchTokensChanged);
        
        // Initialize everything
        gridStyleController.initialize();
        
        // Update the Booru picker popup button
        updateBooruPickerPopupButton();
    }
    
    /// Called when the tokens from titlebarSearchField change
    func searchTokensChanged() {
        // Update the tag display list
        gridStyleController.tagListController.displayTagsFromPost(gridStyleController.tagListController.lastDisplayedPost);
    }
    
    /// Called when the preferences are updated
    func preferencesUpdated() {
        /// The index of the item to select after the Boorus are updated
        var selectionIndex : Int = 0;
        
        // If the selection item isnt nil...
        if(titlebarBooruPickerPopupButton.selectedItem != nil) {
            // Set selection index to the index of the selected item
            selectionIndex = titlebarBooruPickerPopupButton.index(of: titlebarBooruPickerPopupButton.selectedItem!);
        }
        
        // Update the Searching Boorus
        updateBooruPickerPopupButton();
        
        // Reselect the previous item
        titlebarBooruPickerPopupButton.selectItem(at: selectionIndex);
        
        // If the selected item is now nil...
        if(titlebarBooruPickerPopupButton.selectedItem == nil) {
            // Select the last item in titlebarBooruPickerPopupButton
            titlebarBooruPickerPopupButton.selectItem(at: titlebarBooruPickerPopupButton.index(of: titlebarBooruPickerPopupButton.lastItem!));
        }
    }
    
    /// Saves the given BCBooruCollectionViewItems
    func saveBooruItems(_ items : [BCBooruCollectionViewItem]) {
        // If there is at least one item in items...
        if(items.count > 0) {
            /// The open panel to get the directory to save the images to
            let saveDirectoryOpenPanel : NSOpenPanel = NSOpenPanel();
            
            // Only allow single folders
            saveDirectoryOpenPanel.allowsMultipleSelection = false;
            saveDirectoryOpenPanel.canChooseFiles = false;
            saveDirectoryOpenPanel.canChooseDirectories = true;
            
            // Set the prompt to "Save"
            saveDirectoryOpenPanel.prompt = "Save";
            
            // Run the open panel, and if the user hits "Save"...
            if(Bool(saveDirectoryOpenPanel.runModal() as NSNumber)) {
                /// The directory we are saving the images to
                let saveDirectory : String = saveDirectoryOpenPanel.url!.absoluteString.removingPercentEncoding!.replacingOccurrences(of: "file://", with: "");
                
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
                    self.downloadBooruItems(downloadItems, saveDirectory: saveDirectory, tags: titlebarSearchField.stringValue, count: downloadItems.count);
                }
            }
        }
        // If items is blank...
        else {
            // Print that there were no passed items to save
            print("BCViewController: Cant save empty array of BCBooruCollectionViewItems");
        }
    }
    
    /// The actual downloading part of saveBooruItems, saves the given items to the given path, uses tags and count when showing the download completed notification
    private func downloadBooruItems(_ items : [BCBooruCollectionViewItem], saveDirectory : String, tags : String, count : Int) -> Void {
        var items = items
        if let currentSaveItem = items.popLast() {
            // Print what image we are saving
            print("BCViewController: Saving \(currentSaveItem.representedPost!.imageUrl)");
            
            /// The name of the image file
            var imageFileName : String = (NSApplication.shared().delegate as! BCAppDelegate).preferences.imageSaveFormat;
            
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
            
            // If we have already downloaded the image...
            if(currentSaveItem.finishedLoadingImage) {
                // Save the image asynchronously so it doesn't lag the interface
                DispatchQueue.global(qos: DispatchQoS.default.qosClass).async {
                    // Write the image to the chosen directory with the generated file name
                    currentSaveItem.image.saveTo(saveDirectory + imageFileName, fileType: BCImageUtilities().fileTypeFromExtension((NSString(string: currentSaveItem.representedPost!.imageUrl).pathExtension))!);
                    
                    // Print that we saved the image
                    print("BCViewController: Saved image to \"\(saveDirectory + imageFileName)\"");
                }
                
                // Save the image to disk, asynchronously
                DispatchQueue.main.async {
                    // Add the ID of this post to the current searching Booru's downloaded posts
                    self.currentSelectedSearchingBooru?.addIDToDownloadHistory(currentSaveItem.representedPost!.id);
                    
                    // Download the next item
                    self.downloadBooruItems(items, saveDirectory: saveDirectory, tags: tags, count: count);
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
                                    // Write the image to the chosen directory with the generated file name
                                    currentSaveItem.image.saveTo(saveDirectory + imageFileName, fileType: BCImageUtilities().fileTypeFromExtension((NSString(string: currentSaveItem.representedPost!.imageUrl).pathExtension))!);
                                    
                                    // Print that we saved the image
                                    print("BCViewController: Saved image to \"\(saveDirectory + imageFileName)\"");
                                }
                                
                                // Dispatch onto the main queue
                                DispatchQueue.main.async {
                                    // Add the ID of this post to the current searching Booru's downloaded posts
                                    self.currentSelectedSearchingBooru?.addIDToDownloadHistory(currentSaveItem.representedPost!.id);
                                    
                                    // Download the next item
                                    self.downloadBooruItems(items, saveDirectory: saveDirectory, tags: tags, count: count);
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
    
    /// Updates currentSelectedSearchingBooru to match the selected item in titlebarBooruPickerPopupButton
    func updateSelectedSearchingBooru() {
        // Clear the current searching Booru's last search
        currentSelectedSearchingBooru?.utilties.lastSearch = "";
        
        // If there isnt one item with a title of "No Boorus Added" in titlebarBooruPickerPopupButton...
        if(titlebarBooruPickerPopupButton.itemArray.count != 1 && titlebarBooruPickerPopupButton.itemArray[0].title != "No Boorus Added") {
            // Set the selected searching Booru to the selected Booru
            currentSelectedSearchingBooru = (NSApplication.shared().delegate as! BCAppDelegate).preferences.booruHosts[titlebarBooruPickerPopupButton.index(of: titlebarBooruPickerPopupButton.selectedItem!)];
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
        titlebarSearchField.tokenBooru = currentSelectedSearchingBooru;
    }
    
    /// Updates titlebarBooruPickerPopupButton to match the Boorus listed in the user's added Boorus
    func updateBooruPickerPopupButton() {
        // Clear all the current items in titlebarBooruPickerPopupButton
        titlebarBooruPickerPopupButton.removeAllItems();
        
        // For every Booru in the user's Boorus...
        for(_, currentBooruHost) in (NSApplication.shared().delegate as! BCAppDelegate).preferences.booruHosts.enumerated() {
            // Add the current item to titlebarBooruPickerPopupButton
            titlebarBooruPickerPopupButton.addItem(withTitle: currentBooruHost.name);
        }
        
        // If there arent any items in titlebarBooruPickerPopupButton...
        if(titlebarBooruPickerPopupButton.menu?.items.count < 1) {
            // Add an item saying "No Boorus Added" to titlebarBooruPickerPopupButton
            titlebarBooruPickerPopupButton.addItem(withTitle: "");
        }
        
        // Update the searching Booru
        updateSelectedSearchingBooru();
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
        // Hide the toolbar
        window.toolbar?.isVisible = false;
        
        // Set the window's appearance to vibrant dark so the fullscreen toolbar is dark
        window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark);
        
        // Update the titlebar items split view left side minimum width
        titlebarItemsSplitViewLeftMinimumWidthConstraint.constant = 166;
    }
    
    func windowDidExitFullScreen(_ notification: Notification) {
        // Show the toolbar
        window.toolbar?.isVisible = true;
        
        // Set back the window's appearance
        window.appearance = NSAppearance(named: NSAppearanceNameAqua);
        
        // Update the titlebar items split view left side minimum width
        titlebarItemsSplitViewLeftMinimumWidthConstraint.constant = 236;
        
        // If we are hiding the titlebar...
        if(!titlebarVisible) {
            // Hide the OSX titlebar
            window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = true;
        }
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
        // Hide the titlebar visual effect view
        titlebarVisualEffectView.isHidden = true;
        
        // If we arent in fullscreen...
        if(!(window.styleMask.contains(NSFullScreenWindowMask))) {
            // Hide the OSX titlebar
            window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = true;
        }
        
        // Update constraints/content insets
        gridStyleController.largeImageViewTopConstraint.constant = 0;
        gridStyleController.booruCollectionViewScrollView.contentInsets.top = 0;
        
        // Redraw the window's content view so we dont get odd vibrancy artifacts
        window.contentView?.needsDisplay = true;
    }
    
    /// Shows the titlebar
    func showTitlebar() {
        // Show the titlebar visual effect view
        titlebarVisualEffectView.isHidden = false;
        
        // Show the OSX titlebar
        window.standardWindowButton(.closeButton)?.superview?.superview?.isHidden = false;
        
        // Update constraints/content insets
        gridStyleController.largeImageViewTopConstraint.constant = 37;
        gridStyleController.booruCollectionViewScrollView.contentInsets.top = 37;
        
        // Redraw the window's content view so we dont get odd vibrancy artifacts
        window.contentView?.needsDisplay = true;
    }
    
    /// Makes the post browser the first responder
    func selectPostBrowser() {
        // Make booruCollectionView the first responder
        window.makeFirstResponder(gridStyleController.booruCollectionView);
    }
    
    /// Makes titlebarSearchField the first responder
    func selectSearchField() {
        // Make titlebarSearchField the first responder
        window.makeFirstResponder(titlebarSearchField);
    }
    
    /// Sets up the menu items for this controller
    func setupMenuItems() {
        // Setup the menu items
        // Set the actions
        (NSApplication.shared().delegate as! BCAppDelegate).menuItemSaveSelectedImages.action = #selector(BCViewController.saveSelectedImages);
        (NSApplication.shared().delegate as! BCAppDelegate).menuItemOpenSelectedPostsInBrowser.action = #selector(BCViewController.openSelectedPostsInBrowser);
        (NSApplication.shared().delegate as! BCAppDelegate).menuItemCopyUrlsOfSelectedPosts.action = #selector(BCViewController.copyUrlsOfSelectedPosts);
        (NSApplication.shared().delegate as! BCAppDelegate).menuItemCopyImageUrlsOfSelectedPosts.action = #selector(BCViewController.copyImageUrlsOfSelectedPosts);
        (NSApplication.shared().delegate as! BCAppDelegate).menuItemCopyAllPreviouslyCopiedPostUrls.action = #selector(BCViewController.copyPreviouslyCopiedPostUrls);
        (NSApplication.shared().delegate as! BCAppDelegate).menuItemCopyAllPreviouslyCopiedImageUrls.action = #selector(BCViewController.copyPreviouslyCopiedImageUrls);
        (NSApplication.shared().delegate as! BCAppDelegate).menuItemToggleTitlebar.action = #selector(BCViewController.toggleTitlebar);
        (NSApplication.shared().delegate as! BCAppDelegate).menuItemSelectSearchField.action = #selector(BCViewController.selectSearchField);
        (NSApplication.shared().delegate as! BCAppDelegate).menuItemSelectPostBrowser.action = #selector(BCViewController.selectPostBrowser);
    }
    
    /// Styles the window
    func styleWindow() {
        // Get the window
        window = NSApplication.shared().windows.last!;
        
        // Set the window's delegate
        window.delegate = self;
        
        // Style the titlebar
        window.titlebarAppearsTransparent = true;
        window.titleVisibility = .hidden;
        
        window.styleMask.insert(NSFullSizeContentViewWindowMask);
        window.toolbar?.showsBaselineSeparator = false;
        
        // Set the visual effects views' materials
        titlebarVisualEffectView.material = .dark;
        backgroundVisualEffectView.material = .dark;
    }
}
