//
//  PreferencesGeneralController.swift
//  Booru-chan
//
//  Created by Ushio on 2/3/17.
//

import Cocoa

class PreferencesGeneralController: NSViewController {
    
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
    
    private var preferences : Preferences {
        return (NSApp.delegate as! AppDelegate).preferences;
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
        imageSavingFormatTextField.stringValue = preferences.imageFilenameFormat;
        themePopUpButton.selectItem(withTag: preferences.theme.rawValue);
        indicateDownloadedPostsCheckbox.state = NSControl.StateValue(rawValue: Int(truncating: preferences.indicateDownloadedPosts as NSNumber));
        notifyWhenDownloadsFinishCheckbox.state = NSControl.StateValue(rawValue: Int(truncating: preferences.notifyWhenDownloadsFinished as NSNumber));
    }
    
    private func save() {
        preferences.imageFilenameFormat = imageSavingFormatTextField.stringValue;
        preferences.theme = Theme(rawValue: themePopUpButton.selectedTag())!;
        preferences.indicateDownloadedPosts = indicateDownloadedPostsCheckbox.state.rawValue == 1;
        preferences.notifyWhenDownloadsFinished = notifyWhenDownloadsFinishCheckbox.state.rawValue == 1;
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "Preferences.Updated"), object: nil);
    }
}
