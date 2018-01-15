//
//  AppDelegate.swift
//  Booru-chan
//
//  Created by Ushio on 2016-04-23.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    static let appSupportFolder = "\(NSHomeDirectory())/Library/Application Support/Booru-chan";
    static let cacheFolder = "\(appSupportFolder)/caches";

    //todo: make global preferences object a static value in the preferences class
    private(set) var preferences = Preferences();
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createApplicationSupportFolders();
        loadPreferences();

        NSUserNotificationCenter.default.delegate = self;
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true;
    }
    
    private func createApplicationSupportFolders() {
        FileManager.default.createFolder(at: AppDelegate.appSupportFolder);
        FileManager.default.createFolder(at: AppDelegate.cacheFolder);
    }

    private func savePreferences() {
        let data = NSKeyedArchiver.archivedData(withRootObject: preferences);
        UserDefaults.standard.set(data, forKey: "preferences");
        UserDefaults.standard.synchronize();
    }

    private func loadPreferences() {
        if let data = UserDefaults.standard.object(forKey: "preferences") as? Data {
            preferences = (NSKeyedUnarchiver.unarchiveObject(with: data) as! Preferences);
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        savePreferences();
    }
}
