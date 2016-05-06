//
//  BCViewController.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa
import Alamofire

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
    @IBAction func titlebarBooruPickerPopupButtonItemSelected(sender: AnyObject) {
        // Update the searching Booru
        updateSelectedSearchingBooru();
    }
    
    /// The token field in the titlebar for searching
    @IBOutlet var titlebarSearchField: BCBooruSearchTokenField!
    
    /// When the user enters text into titlebarSearchField...
    @IBAction func titlebarSearchFieldTextEntered(sender: NSTokenField) {
        // Search for the entered text(It replaces commas with spaces because when NSTokenField gives you it's stringValue, there is a comma in between each token)
        gridStyleController.searchFor(sender.stringValue.stringByReplacingOccurrencesOfString(",", withString: " "));
        
        // Add all the searched tags to the current Booru's history
        // For every entered token...
        for(_, currentToken) in sender.tokens.enumerate() {
            // Add the current token to the search history of the current Searching Booru
            currentSelectedSearchingBooru?.addTagToHistory(currentToken);
        }
    }
    
    /// The current Booru the user selected to search from
    var currentSelectedSearchingBooru : BCBooruHost? = nil;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Tell BCAppDelegate to load the preferences
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).loadPreferences();
        
        // Style the window
        styleWindow();
        
        // Setup the menu items
        setupMenuItems();
        
        // Add the preferences updated observer
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("preferencesUpdated"), name: "BCPreferences.Updated", object: nil);
        
        // Set the target and action for the titlebar search field's tokens changed event
        titlebarSearchField.tokensChangedTarget = self;
        titlebarSearchField.tokensChangedAction = Selector("searchTokensChanged");
        
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
            selectionIndex = titlebarBooruPickerPopupButton.indexOfItem(titlebarBooruPickerPopupButton.selectedItem!);
        }
        
        // Update the Searching Boorus
        updateBooruPickerPopupButton();
        
        // Reselect the previous item
        titlebarBooruPickerPopupButton.selectItemAtIndex(selectionIndex);
        
        // If the selected item is now nil...
        if(titlebarBooruPickerPopupButton.selectedItem == nil) {
            // Select the last item in titlebarBooruPickerPopupButton
            titlebarBooruPickerPopupButton.selectItemAtIndex(titlebarBooruPickerPopupButton.indexOfItem(titlebarBooruPickerPopupButton.lastItem!));
        }
    }
    
    /// Saves the given BCBooruCollectionViewItems
    func saveBooruItems(items : [BCBooruCollectionViewItem]) {
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
            if(Bool(saveDirectoryOpenPanel.runModal())) {
                /// The directory we are saving the images to
                let saveDirectory : String = saveDirectoryOpenPanel.URL!.absoluteString.stringByRemovingPercentEncoding!.stringByReplacingOccurrencesOfString("file://", withString: "");
                
                // Print how many images we are saving and where
                print("BCViewController: Saving \(items.count) image(s) to \"\(saveDirectory)\"");
                
                // For every item to save...
                for(currentIndex, currentSaveItem) in items.enumerate() {
                    /// The name of the image file
                    var imageFileName : String = (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.imageSaveFormat;
                    
                    // Replace %id% with the image's id
                    imageFileName = imageFileName.stringByReplacingOccurrencesOfString("%id%", withString: String(currentSaveItem.representedPost!.id));
                    
                    // Replace %booru% with the post's Booru's name
                    imageFileName = imageFileName.stringByReplacingOccurrencesOfString("%booru%", withString: String(currentSelectedSearchingBooru!.name));
                    
                    /// Every tag of this post(With spaces in between) put into a string
                    var tagsString : String = "";
                    
                    // For every tag on this post...
                    for(_, currentTag) in currentSaveItem.representedPost!.tags.enumerate() {
                        // Add the current tag to tagsString
                        tagsString += currentTag + " ";
                    }
                    
                    // If tagsString isnt blank...
                    if(tagsString != "") {
                        // Remove the trailing space that was added from adding the tags
                        tagsString = tagsString.substringToIndex(tagsString.endIndex.predecessor());
                    }
                    
                    // Replace %tags% with the tags string
                    imageFileName = imageFileName.stringByReplacingOccurrencesOfString("%tags%", withString: tagsString);
                    
                    // If imageFileName has over 250 characters...
                    if(imageFileName.characters.count > 250) {
                        // Cut imageFileName down to 250 characters
                        imageFileName = imageFileName.substringToIndex(imageFileName.startIndex.advancedBy(250));
                        
                        /// The indexes of all the spaces in imageFileName
                        let indexesOfSpaceInImageFileName = imageFileName.characters.enumerate()
                            .filter { $0.element == " " }
                            .map { $0.index }
                        
                        // Cut imageFileName down to the last space
                        imageFileName = imageFileName.substringToIndex(imageFileName.startIndex.advancedBy(indexesOfSpaceInImageFileName.last!));
                    }
                    
                    // Add the extension onto the end
                    imageFileName += "." + NSString(string: currentSaveItem.representedPost!.imageUrl).pathExtension;
                    
                    // If we have already downloaded the image...
                    if(currentSaveItem.finishedLoadingImage) {
                        // Save the image to disk, asynchronously
                        dispatch_async(dispatch_get_main_queue()) {
                            // Write the image to the chosen directory with the generated file name
                            currentSaveItem.image.TIFFRepresentation?.writeToFile(saveDirectory + imageFileName, atomically: true);
                            
                            // Print that we saved the image
                            print("BCViewController: Saved image to \"\(saveDirectory + imageFileName)\"");
                            
                            // Add the ID of this post to the current searching Booru's downloaded posts
                            self.currentSelectedSearchingBooru?.addIDToDownloadHistory(currentSaveItem.representedPost!.id);
                            
                            // If this is the last item to download...
                            if(currentIndex == items.count - 1) {
                                // Reload the downloaded indicators for the grid style controller
                                self.gridStyleController.reloadDownloadedIndicators();
                            }
                        }
                    }
                    // If we have to download the image...
                    else {
                        // Download the post item's full size image
                        Alamofire.request(.GET, currentSaveItem.representedPost!.imageUrl).response { (request, response, data, error) in
                            // If data isnt nil...
                            if(data != nil) {
                                /// The downloaded image
                                let image : NSImage? = NSImage(data: data!);
                                
                                // If image isnt nil...
                                if(image != nil) {
                                    // Store the image in the post item
                                    currentSaveItem.image = image!;
                                    
                                    // Dispatch onto the main queue
                                    dispatch_async(dispatch_get_main_queue()) {
                                        // Write the image to the chosen directory with the generated file name
                                        currentSaveItem.image.TIFFRepresentation?.writeToFile(saveDirectory + imageFileName, atomically: true);
                                        
                                        // Print that we saved the image
                                        print("BCViewController: Saved image to \"\(saveDirectory + imageFileName)\"");
                                        
                                        // Add the ID of this post to the current searching Booru's downloaded posts
                                        self.currentSelectedSearchingBooru?.addIDToDownloadHistory(currentSaveItem.representedPost!.id);
                                        
                                        // If this is the last item to download...
                                        if(currentIndex == items.count - 1) {
                                            // Reload the downloaded indicators for the grid style controller
                                            self.gridStyleController.reloadDownloadedIndicators();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        // If items is blank...
        else {
            // Print that there were no passed items to save
            print("BCViewController: Cant save empty array of BCBooruCollectionViewItems");
        }
    }
    
    /// Saves the selected Booru post images
    func saveSelectedImages() {
        // Save the selected items
        saveBooruItems(gridStyleController.getSelectedBooruItems());
    }
    
    /// Updates currentSelectedSearchingBooru to match the selected item in titlebarBooruPickerPopupButton
    func updateSelectedSearchingBooru() {
        // Clear the current searching Booru's last search
        currentSelectedSearchingBooru?.utilties.lastSearch = "";
        
        // If there isnt one item with a title of "No Boorus Added" in titlebarBooruPickerPopupButton...
        if(titlebarBooruPickerPopupButton.itemArray.count != 1 && titlebarBooruPickerPopupButton.itemArray[0].title != "No Boorus Added") {
            // Set the selected searching Booru to the selected Booru
            currentSelectedSearchingBooru = (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts[titlebarBooruPickerPopupButton.indexOfItem(titlebarBooruPickerPopupButton.selectedItem!)];
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
        for(_, currentBooruHost) in (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts.enumerate() {
            // Add the current item to titlebarBooruPickerPopupButton
            titlebarBooruPickerPopupButton.addItemWithTitle(currentBooruHost.name);
        }
        
        // If there arent any items in titlebarBooruPickerPopupButton...
        if(titlebarBooruPickerPopupButton.menu?.itemArray.count < 1) {
            // Add an item saying "No Boorus Added" to titlebarBooruPickerPopupButton
            titlebarBooruPickerPopupButton.addItemWithTitle("");
        }
        
        // Update the searching Booru
        updateSelectedSearchingBooru();
    }
    
    func windowWillEnterFullScreen(notification: NSNotification) {
        // Hide the toolbar
        window.toolbar?.visible = false;
        
        // Set the window's appearance to vibrant dark so the fullscreen toolbar is dark
        window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark);
        
        // Update the titlebar items split view left side minimum width
        titlebarItemsSplitViewLeftMinimumWidthConstraint.constant = 166;
    }
    
    func windowDidExitFullScreen(notification: NSNotification) {
        // Show the toolbar
        window.toolbar?.visible = true;
        
        // Set back the window's appearance
        window.appearance = NSAppearance(named: NSAppearanceNameAqua);
        
        // Update the titlebar items split view left side minimum width
        titlebarItemsSplitViewLeftMinimumWidthConstraint.constant = 236;
        
        // If we are hiding the titlebar...
        if(!titlebarVisible) {
            // Hide the OSX titlebar
            window.standardWindowButton(.CloseButton)?.superview?.superview?.hidden = true;
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
        titlebarVisualEffectView.hidden = true;
        
        // If we arent in fullscreen...
        if(!((window.styleMask & NSFullScreenWindowMask) > 0)) {
            // Hide the OSX titlebar
            window.standardWindowButton(.CloseButton)?.superview?.superview?.hidden = true;
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
        titlebarVisualEffectView.hidden = false;
        
        // Show the OSX titlebar
        window.standardWindowButton(.CloseButton)?.superview?.superview?.hidden = false;
        
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
        // Set the targets
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).menuItemSaveSelectedImages.target = self;
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).menuItemToggleTitlebar.target = self;
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).menuItemSelectSearchField.target = self;
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).menuItemSelectPostBrowser.target = self;
        
        // Set the actions
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).menuItemSaveSelectedImages.action = Selector("saveSelectedImages");
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).menuItemToggleTitlebar.action = Selector("toggleTitlebar");
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).menuItemSelectSearchField.action = Selector("selectSearchField");
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).menuItemSelectPostBrowser.action = Selector("selectPostBrowser");
    }
    
    /// Styles the window
    func styleWindow() {
        // Get the window
        window = NSApplication.sharedApplication().windows.last!;
        
        // Set the window's delegate
        window.delegate = self;
        
        // Style the titlebar
        window.titlebarAppearsTransparent = true;
        window.titleVisibility = .Hidden;
        
        window.styleMask |= NSFullSizeContentViewWindowMask;
        window.toolbar?.showsBaselineSeparator = false;
        
        // Set the visual effects views' materials
        titlebarVisualEffectView.material = .Dark;
        backgroundVisualEffectView.material = .Dark;
    }
}