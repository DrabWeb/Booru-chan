//
//  BCAppDelegate
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//

import Cocoa

@NSApplicationMain
class BCAppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    /// The global preferences object
    var preferences : BCPreferencesObject = BCPreferencesObject();
    
    /// File/Save Selected Images (⌘S)
    @IBOutlet weak var menuItemSaveSelectedImages: NSMenuItem!
    
    /// File/Open Selected Posts In Browser
    @IBOutlet weak var menuItemOpenSelectedPostsInBrowser: NSMenuItem!
    
    /// File/Copy URLs of Selected Posts
    @IBOutlet weak var menuItemCopyUrlsOfSelectedPosts: NSMenuItem!
    
    /// File/Copy Image URLs of Selected Posts (⌘C)
    @IBOutlet weak var menuItemCopyImageUrlsOfSelectedPosts: NSMenuItem!
    
    /// File/Copy All Previously Copied Post URLs (⌃⇧⌘C)
    @IBOutlet weak var menuItemCopyAllPreviouslyCopiedPostUrls: NSMenuItem!
    
    /// File/Copy All Previously Copied Image URLs (⌃⌘C)
    @IBOutlet weak var menuItemCopyAllPreviouslyCopiedImageUrls: NSMenuItem!
    
    /// Image/Zoom In (⌘=)
    @IBOutlet weak var menuItemZoomIn: NSMenuItem!
    
    /// Image/Zoom Out (⌘-)
    @IBOutlet weak var menuItemZoomOut: NSMenuItem!
    
    /// Image/Reset Zoom (⌘0)
    @IBOutlet weak var menuItemResetZoom: NSMenuItem!
    
    /// Window/Toggle Titlebar (⌘⌥T)
    @IBOutlet weak var menuItemToggleTitlebar: NSMenuItem!
    
    /// Window/Toggle Post Browser (⌘⌥B)
    @IBOutlet weak var menuItemTogglePostBrowser: NSMenuItem!
    
    /// Window/Toggle Info Bar (⌘⌥I)
    @IBOutlet weak var menuItemToggleInfoBar: NSMenuItem!
    
    /// Window/Toggle Tag List (⌘⌥L)
    @IBOutlet weak var menuItemToggleTagList: NSMenuItem!
    
    /// Window/Select Search Field (⌘F)
    @IBOutlet weak var menuItemSelectSearchField: NSMenuItem!
    
    /// Window/Open Booru Popup (⌃1)
    @IBOutlet weak var menuItemOpenBooruPopup: NSMenuItem!
    
    /// Window/Select Post Browser (⌘B)
    @IBOutlet weak var menuItemSelectPostBrowser: NSMenuItem!
    
    @IBAction func newWindowForTab(_ sender: Any?) {
        
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        // Make the application support folders
        createApplicationSupportFolders();
        
        // Set the notification center delegate
        NSUserNotificationCenter.default.delegate = self;
        
        // Setup the menu items
        setupMenuItems();
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true;
    }
    
    func createApplicationSupportFolders() {
        // If the application support folder doesnt exist...
        if(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Booru-chan/")) {
            do {
                // Make the ~/Library/Application Support/Booru-chan folder
                try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Library/Application Support/Booru-chan/", withIntermediateDirectories: false, attributes: nil);
            }
            catch let error as NSError {
                // Print the error
                print("BCAppDelegate: Error creating Application Support folder, \(error.description)");
            }
        }
        
        // If the caches folder doesnt exist...
        if(!FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Application Support/Booru-chan/caches")) {
            do {
                // Make the ~/Library/Application Support/Booru-chan/caches folder
                try FileManager.default.createDirectory(atPath: NSHomeDirectory() + "/Library/Application Support/Booru-chan/caches", withIntermediateDirectories: false, attributes: nil);
            }
            catch let error as NSError {
                // Print the error
                print("BCAppDelegate: Error creating caches folder, \(error.description)");
            }
        }
    }
    
    /// Sets up all the menu items
    func setupMenuItems() {
        // Setup the menu items
        self.menuItemSaveSelectedImages.action = #selector(BCViewController.saveSelectedImages);
        self.menuItemOpenSelectedPostsInBrowser.action = #selector(BCViewController.openSelectedPostsInBrowser);
        self.menuItemCopyUrlsOfSelectedPosts.action = #selector(BCViewController.copyUrlsOfSelectedPosts);
        self.menuItemCopyImageUrlsOfSelectedPosts.action = #selector(BCViewController.copyImageUrlsOfSelectedPosts);
        self.menuItemCopyAllPreviouslyCopiedPostUrls.action = #selector(BCViewController.copyPreviouslyCopiedPostUrls);
        self.menuItemCopyAllPreviouslyCopiedImageUrls.action = #selector(BCViewController.copyPreviouslyCopiedImageUrls);
        self.menuItemToggleTitlebar.action = #selector(BCViewController.toggleTitlebar);
        self.menuItemSelectSearchField.action = #selector(BCViewController.selectSearchField);
        self.menuItemOpenBooruPopup.action = #selector(BCViewController.openBooruPopup);
        self.menuItemSelectPostBrowser.action = #selector(BCViewController.selectPostBrowser);
        
        self.menuItemTogglePostBrowser.action = #selector(BCViewController.toggleBooruCollectionView);
        self.menuItemToggleInfoBar.action = #selector(BCViewController.toggleInfoBar);
        self.menuItemToggleTagList.action = #selector(BCViewController.toggleTagList);
        self.menuItemZoomIn.action = #selector(BCViewController.zoomIn);
        self.menuItemZoomOut.action = #selector(BCViewController.zoomOut);
        self.menuItemResetZoom.action = #selector(BCViewController.resetZoomWithAnimation);
    }
    
    /// Saves the preferences
    func savePreferences() {
        /// The data for the preferences object
        let data = NSKeyedArchiver.archivedData(withRootObject: preferences);
        
        // Set the standard user defaults preferences key to that data
        UserDefaults.standard.set(data, forKey: "preferences");
        
        // Synchronize the data
        UserDefaults.standard.synchronize();
    }
    
    /// Loads the preferences
    func loadPreferences() {
        // If we have any data to load...
        if let data = UserDefaults.standard.object(forKey: "preferences") as? Data {
            // Set the preferences object to the loaded object
            preferences = (NSKeyedUnarchiver.unarchiveObject(with: data) as! BCPreferencesObject);
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        // Save the preferences
        savePreferences();
    }
}
