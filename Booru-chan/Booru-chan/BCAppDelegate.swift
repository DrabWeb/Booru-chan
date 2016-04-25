//
//  BCAppDelegate
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa

@NSApplicationMain
class BCAppDelegate: NSObject, NSApplicationDelegate {

    /// The global preferences object
    var preferences : BCPreferencesObject = BCPreferencesObject();
    
    /// File/Save Selected Images (⌘S)
    @IBOutlet weak var menuItemSaveSelectedImages: NSMenuItem!
    
    /// Window/Toggle Titlebar (⌘⌥T)
    @IBOutlet weak var menuItemToggleTitlebar: NSMenuItem!
    
    /// Window/Toggle Post Browser (⌘⌥B)
    @IBOutlet weak var menuItemTogglePostBrowser: NSMenuItem!
    
    /// Window/Select Search Field (⌘F)
    @IBOutlet weak var menuItemSelectSearchField: NSMenuItem!
    
    /// Window/Select Post Browser (⌘B)
    @IBOutlet weak var menuItemSelectPostBrowser: NSMenuItem!
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
    }
    
    /// Saves the preferences
    func savePreferences() {
        /// The data for the preferences object
        let data = NSKeyedArchiver.archivedDataWithRootObject(preferences);
        
        // Set the standard user defaults preferences key to that data
        NSUserDefaults.standardUserDefaults().setObject(data, forKey: "preferences");
        
        // Synchronize the data
        NSUserDefaults.standardUserDefaults().synchronize();
    }
    
    /// Loads the preferences
    func loadPreferences() {
        // If we have any data to load...
        if let data = NSUserDefaults.standardUserDefaults().objectForKey("preferences") as? NSData {
            // Set the preferences object to the loaded object
            preferences = (NSKeyedUnarchiver.unarchiveObjectWithData(data) as! BCPreferencesObject);
        }
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
        // Save the preferences
        savePreferences();
    }
}

