//
//  AppDelegate.swift
//  Booru-chan
//
//  Created by Ushio on 2016-04-23.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    //todo: make global preferences object a static value in the preferences class
    var preferences: Preferences = Preferences();
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        createApplicationSupportFolders();
        loadPreferences();

        NSUserNotificationCenter.default.delegate = self;
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true;
    }
    
    private func createApplicationSupportFolders() {
        func createFolder(at path: String) {
            if !FileManager.default.fileExists(atPath: path) {
                do {
                    try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil);
                }
                catch let error as NSError {
                    print("AppDelegate: Error creating folder at \(path), \(error.description)");
                }
            }
        }

        let f = "\(NSHomeDirectory())/Library/Application Support/Booru-chan"

        createFolder(at: f);
        createFolder(at: "\(f)/caches");
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
