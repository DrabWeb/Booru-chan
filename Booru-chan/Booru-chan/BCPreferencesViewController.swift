//
//  BCPreferencesViewController.swift
//  Booru-chan
//
//  Created by Seth on 2016-05-04.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa

class BCPreferencesViewController: NSViewController, NSWindowDelegate {
    
    /// The main window of this view controller
    var preferencesWindow : NSWindow = NSWindow();
    
    /// The visual effect view for the background of the window
    @IBOutlet var backgroundVisualEffectView: NSVisualEffectView!
    
    /// The visual effect view for the titlebar of the window
    @IBOutlet var titlebarVisualEffectView: NSVisualEffectView!
    
    /// The scroll view for booruTableView
    @IBOutlet var booruTableViewScrollView: NSScrollView!
    
    /// The table view for letting the user modify their Boorus
    @IBOutlet var booruTableView: NSTableView!
    
    /// The popup button for letting the user set the type of a Booru a Booru is
    @IBOutlet var booruTypePopupButton: NSPopUpButton!
    
    /// When we select an item in booruTypePopupButton...
    @IBAction func booruTypePopupButtonSelected(sender: AnyObject) {
        // Print what we are doing
        print("BCPreferencesViewController: Changing type for \"\(currentEditingBooruHost.name)\" to \"\(BCBooruType(rawValue: booruTypePopupButton.selectedTag())!)\"");
        
        // Update the current editing Booru's type
        currentEditingBooruHost.type = BCBooruType(rawValue: booruTypePopupButton.selectedTag())!;
        
        // Refresh the Booru's utilities
        currentEditingBooruHost.refreshUtilities();
        
        // Post the preferences updated notification
        postUpdatedNotification();
    }
    
    /// The popup button for selecting the maximum rating of a Booru
    @IBOutlet var booruMaximumRatingPoupButton: NSPopUpButton!
    
    /// When we select an item in booruMaximumRatingPoupButton...
    @IBAction func booruMaximumRatingPoupButtonSelected(sender: AnyObject) {
        // Print what we are doing
        print("BCPreferencesViewController: Changing maximum rating of \"\(currentEditingBooruHost.name)\" to \"\(BCRating(rawValue: booruMaximumRatingPoupButton.selectedTag())!)\"");
        
        // Update the maximum rating of the current editing Booru
        currentEditingBooruHost.maximumRating = BCRating(rawValue: booruMaximumRatingPoupButton.selectedTag())!;
        
        // Reload the editing Booru's utilities
        currentEditingBooruHost.refreshUtilities();
        
        // Post the preferences updated notification
        postUpdatedNotification();
    }
    
    /// The buttno to let the user remove Boorus from their Boorus
    @IBOutlet var booruRemoveButton: NSButton!
    
    /// When we press booruRemoveButton...
    @IBAction func booruRemoveButtonPressed(sender: AnyObject) {
        // If there is more than one Booru in the user's Booru hosts...
        if((NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts.count > 1) {
            // Remove the selected Booru from the user's hosts
            (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts.removeAtIndex(booruTableView.selectedRow);
            
            // Reload the table view
            booruTableView.reloadData();
            
            // Post the preferences updated notification
            postUpdatedNotification();
        }
    }
    
    /// When we press the add button to add a Booru to the user's Boorus...
    @IBAction func booruAddButtonPressed(sender: AnyObject) {
        // Add an empty Booru onto the user's Booru hosts
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts.append(BCBooruHost(name: "Name", type: BCBooruType.Moebooru, pagePostLimit: 40, url: "URL", maximumRating: BCRating.Explicit));
        
        // Reload the table view
        booruTableView.reloadData();
        
        // Deselect all the items in the Booru table view
        booruTableView.deselectAll(self);
        
        // Select the last Booru in the table view
        booruTableView.selectRowIndexes(NSIndexSet(index: (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts.count - 1), byExtendingSelection: false);
        
        // Post the preferences updated notification
        postUpdatedNotification();
    }
    
    /// The text field for setting how many posts to display per page in the Booru browser
    @IBOutlet weak var booruPostsPerPageTextField: NSTextField!
    
    /// When the user enters text into booruPostsPerPageTextField...
    @IBAction func booruPostsPerPageTextFieldEntered(sender: AnyObject) {
        // Print what we are doing
        print("BCPreferencesViewController: Changing page post limit of \"\(currentEditingBooruHost.name)\" to \"\(booruPostsPerPageTextField.integerValue)\"");
        
        // Update the current editing Booru's posts per page
        currentEditingBooruHost.pagePostLimit = booruPostsPerPageTextField.integerValue;
        
        // Refresh the Booru's utilities
        currentEditingBooruHost.refreshUtilities();
        
        // Post the preferences updated notification
        postUpdatedNotification();
    }
    
    /// When we press the "Clear Tags" button...
    @IBAction func booruClearTagHistoryButtonPressed(sender: AnyObject) {
        // Clear the tag history for the current editing Booru
        currentEditingBooruHost.tagHistory = [];
        
        // Update the host's utilties
        currentEditingBooruHost.refreshUtilities();
        
        // Post the notification saying we update the preferences
        postUpdatedNotification();
    }
    
    /// When we press the "Clear Downloads" button...
    @IBAction func booruClearDownloadHistoryButtonPressed(sender: AnyObject) {
        // Clear the download history for the current editing Booru
        currentEditingBooruHost.downloadedPosts = [];
        
        // Update the host's utilties
        currentEditingBooruHost.refreshUtilities();
        
        // Post the notification saying we update the preferences
        postUpdatedNotification();
    }
    
    /// The text field for setting the format of saved image's file names
    @IBOutlet var generalImageSavingFormatTextField: NSTextField!
    
    /// When we stop editing generalImageSavingFormatTextField...
    @IBAction func generalImageSavingFormatTextFieldEndedEditing(sender: AnyObject) {
        // Set the preferences value to the entered text
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.imageSaveFormat = generalImageSavingFormatTextField.stringValue;
    }
    
    /// The current Booru Host we are editing
    var currentEditingBooruHost : BCBooruHost = BCBooruHost();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Style the window
        styleWindow();
        
        // Display the info from the first Booru host
        displayInfoFromHost((NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts[0]);
        
        // Set the image file name format text field's value to the current image file name value
        generalImageSavingFormatTextField.stringValue = (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.imageSaveFormat;
    }
    
    /// Displays the info of the given host in the Booru tab's editor
    func displayInfoFromHost(host : BCBooruHost) {
        // Set currentEditingBooruHost
        currentEditingBooruHost = host;
        
        // Show the info
        booruPostsPerPageTextField.integerValue = host.pagePostLimit;
        booruTypePopupButton.selectItemWithTag(host.type.rawValue);
        booruMaximumRatingPoupButton.selectItemWithTag(host.maximumRating.rawValue);
    }
    
    /// Called when the user changes the name of a Booru list item
    func booruNameTextFieldEdited(sender: NSTextField) {
        // Print what we are doing
        print("BCPreferencesViewController: Changing name of \"\(currentEditingBooruHost.name)\" to \"\(sender.stringValue)\"");
        
        // Change the name of the Booru that the user edited
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts[sender.tag].name = sender.stringValue;
        
        // Update the host's utilties
        currentEditingBooruHost.refreshUtilities();
        
        // Post the notification saying we update the preferences
        postUpdatedNotification();
    }
    
    
    /// Called when the user changes the URL of a Booru list item
    func booruUrlTextFieldEdited(sender: NSTextField) {
        // Print what we are doing
        print("BCPreferencesViewController: Changing URL of \"\(currentEditingBooruHost.name)\" to \"\(sender.stringValue)\"");
        
        // Change the URL of the Booru that the user edited
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts[sender.tag].url = sender.stringValue;
        
        // Update the host's utilties
        currentEditingBooruHost.refreshUtilities();
        
        // Post the notification saying we update the preferences
        postUpdatedNotification();
    }
    
    /// Posts the notification saying the preferences have been updated
    func postUpdatedNotification() {
        // If there is only one item in the user's Booru hosts...
        if((NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts.count == 1) {
            // Disable the remove button
            booruRemoveButton.enabled = false;
        }
        // If there are more than one items in the user's Booru hosts...
        else if( (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts.count > 1) {
            // Enable the remove button
            booruRemoveButton.enabled = true;
        }
        
        // Post the notification
        NSNotificationCenter.defaultCenter().postNotificationName("BCPreferences.Updated", object: nil);
        
        // Print that we posted the notification
        print("BCPreferencesViewController: Posted preferences updated notification");
    }
    
    func windowDidResignKey(notification: NSNotification) {
        // Post the notification saying we update the preferences
        postUpdatedNotification();
    }
    
    /// Styles the window
    func styleWindow() {
        // Get the window
        preferencesWindow = NSApplication.sharedApplication().windows.last!;
        
        // Set the window's delegate
        preferencesWindow.delegate = self;
        
        // Style the window
        preferencesWindow.standardWindowButton(.MiniaturizeButton)?.hidden = true;
        preferencesWindow.standardWindowButton(.ZoomButton)?.hidden = true;
        preferencesWindow.titleVisibility = .Hidden;
        preferencesWindow.titlebarAppearsTransparent = true;
        
        // Style the visual effect views
        titlebarVisualEffectView.material = .Titlebar;
        backgroundVisualEffectView.material = .Dark;
    }
    
    override func viewWillAppear() {
        // Center the window
        preferencesWindow.center();
    }
}

extension BCPreferencesViewController: NSTableViewDataSource {
    func numberOfRowsInTableView(aTableView: NSTableView) -> Int {
        // Return the amount of items in the preference's Booru hosts
        return (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts.count;
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        /// The cell view for the cell we want to modify
        let cellView: NSTableCellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: nil) as! NSTableCellView;
        
        /// The data for this cell
        let cellData : BCBooruHost = (NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts[row];
        
        // Set the cell's text field's tag to the row it is at
        cellView.textField?.tag = row;
        
        // If this is the name column...
        if(tableColumn!.identifier == "Name Column") {
            // Display the cell's data
            cellView.textField?.stringValue = cellData.name;
            
            // Set the target and action of the text field
            cellView.textField?.target = self;
            cellView.textField?.action = Selector("booruNameTextFieldEdited:");
            
            // Return the modified cell view
            return cellView;
        }
        // If this is the URL column...
        else if(tableColumn!.identifier == "URL Column") {
            // Display the cell's data
            cellView.textField?.stringValue = cellData.url;
            
            // Set the target and action of the text field
            cellView.textField?.target = self;
            cellView.textField?.action = Selector("booruUrlTextFieldEdited:");
            
            // Return the modified cell view
            return cellView;
        }
        
        // Return the unmodified cell view, we dont need to do anything
        return cellView;
    }
}

extension BCPreferencesViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(notification: NSNotification) {
        /// The row we selected
        let selectedRow : Int = (notification.object as! NSTableView).selectedRow;
        
        displayInfoFromHost((NSApplication.sharedApplication().delegate as! BCAppDelegate).preferences.booruHosts[selectedRow]);
    }
}