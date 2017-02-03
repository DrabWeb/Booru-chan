//
//  BCPreferencesGeneralViewController.swift
//  Booru-chan
//
//  Created by Ushio on 2/3/17.
//

import Cocoa

class BCPreferencesGeneralViewController: NSViewController {
    
    @IBOutlet weak var imageSavingFormatTextField: NSTextField!
    @IBAction func imageSavingFormatTextField(_ sender: NSTextField) {
        save();
    }
    
    @IBOutlet weak var themePopUpButton: NSPopUpButton!
    @IBAction func themePopUpButton(_ sender: NSPopUpButton) {
        save();
    }
    
    @IBOutlet weak var indicateDownloadedPostsCheckbox: NSButton!
    @IBAction func indicateDownloadedPostsCheckbox(_ sender: NSButton) {
        save();
    }
    
    @IBOutlet weak var notifyWhenDownloadsFinishCheckbox: NSButton!
    @IBAction func notifyWhenDownloadsFinishCheckbox(_ sender: NSButton) {
        save();
    }
    
    private var preferences : BCPreferencesObject {
        return (NSApp.delegate as! BCAppDelegate).preferences;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        load();
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear();

        save();
    }
    
    private func load() {
        imageSavingFormatTextField.stringValue = preferences.imageSaveFormat;
        themePopUpButton.selectItem(withTag: preferences.theme.rawValue);
        indicateDownloadedPostsCheckbox.state = Int(preferences.indicateDownloadedPosts as NSNumber);
        notifyWhenDownloadsFinishCheckbox.state = Int(preferences.notifyWhenDownloadsFinished as NSNumber);
    }
    
    private func save() {
        preferences.imageSaveFormat = imageSavingFormatTextField.stringValue;
        preferences.theme = BCTheme(rawValue: themePopUpButton.selectedTag())!;
        preferences.indicateDownloadedPosts = indicateDownloadedPostsCheckbox.state == 1;
        preferences.notifyWhenDownloadsFinished = notifyWhenDownloadsFinishCheckbox.state == 1;
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "BCPreferences.Updated"), object: nil);
    }
}
