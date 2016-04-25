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
    
    /// The text field in the titlebar for searching
    @IBOutlet var titlebarSearchField: BCAlwaysActiveTextField!
    
    /// When the user enters text into titlebarSearchField...
    @IBAction func titlebarSearchFieldTextEntered(sender: AnyObject) {
        // Search for the entered text
        gridStyleController.searchFor(titlebarSearchField.stringValue);
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
        
        // Initialize everything
        gridStyleController.initialize();
        
        // Update the Booru picker popup button
        updateBooruPickerPopupButton();
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
                for(_, currentSaveItem) in items.enumerate() {
                    /// The name of the image file
                    var imageFileName : String = (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.imageSaveFormat;
                    
                    // Replace %id% with the image's id
                    imageFileName = imageFileName.stringByReplacingOccurrencesOfString("%id%", withString: String(currentSaveItem.representedPost!.id));
                    
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
                    
                    // Add the extension onto the end
                    imageFileName += ".png";
                    
                    // If we have already downloaded the image...
                    if(currentSaveItem.finishedLoadingImage) {
                        // Save the image to disk, asynchronously
                        dispatch_async(dispatch_get_main_queue()) {
                            // Write the image to the chosen directory with the generated file name
                            currentSaveItem.image.TIFFRepresentation?.writeToFile(saveDirectory + imageFileName, atomically: false);
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
                                    
                                    // Write the image to the chosen directory with the generated file name
                                    currentSaveItem.image.TIFFRepresentation?.writeToFile(saveDirectory + imageFileName, atomically: false);
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