//
//  PreferencesGeneralController.swift
//  Booru-chan
//
//  Created by Ushio on 2/3/17.
//

import Cocoa

class PreferencesGeneralController: NSViewController {

    private var preferences: Preferences {
        return (NSApp.delegate as! AppDelegate).preferences;
    }

    @IBOutlet private weak var imageSavingFormatTextField: NSTextField!
    @IBOutlet private weak var themePopUpButton: NSPopUpButton!
    @IBOutlet private weak var indicateDownloadedPostsCheckbox: NSButton!
    @IBOutlet private weak var notifyWhenDownloadsFinishCheckbox: NSButton!

    @IBAction func savePreferences(_ sender: Any!) {
        save();
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
        indicateDownloadedPostsCheckbox.state = preferences.indicateDownloadedPosts ? .on : .off;
        notifyWhenDownloadsFinishCheckbox.state = preferences.notifyWhenDownloadsFinished ? .on : .off;
    }
    
    private func save() {
        preferences.imageFilenameFormat = imageSavingFormatTextField.stringValue;
        preferences.theme = Theme(rawValue: themePopUpButton.selectedTag())!;
        preferences.indicateDownloadedPosts = indicateDownloadedPostsCheckbox.state == .on;
        preferences.notifyWhenDownloadsFinished = notifyWhenDownloadsFinishCheckbox.state == .on;
        
        NotificationCenter.default.post(name: Notification.Name(rawValue: "Preferences.Updated"), object: nil);
    }
}
