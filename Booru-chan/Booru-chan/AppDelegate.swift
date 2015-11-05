//
//  AppDelegate.swift
//  Booru-chan
//
//  Created by Seth on 2015-11-01.
//  Copyright © 2015 DrabWeb. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSTableViewDelegate {

    // A reference to the sidebar table view
    @IBOutlet weak var viewController: ViewController!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    // When the table view selection changes...
    func tableViewSelectionDidChange(notification: NSNotification) {
        // Print to the log that our selection has changed
        print("Sidebar tableview changing selection...");
        
        // Get the table view from the notification
        let tableView = notification.object as! NSTableView;
        
        // Get the selected row from the table view
        var selectedRow = tableView.selectedRow;
        
        // Select the item at that index
        viewController.selectImageAtIndex(selectedRow);
    }

}

