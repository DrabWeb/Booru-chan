//
//  PreferencesBoorusController.swift
//  Booru-chan
//
//  Created by Ushio on 2/3/17.
//

import Cocoa

class PreferencesBoorusController: NSViewController {
    
    @IBOutlet weak var tableView: NSTableView!
    
    @IBOutlet weak var typePopUpButton: NSPopUpButton!
    @IBAction func typePopUpButton(_ sender: NSPopUpButton) {
        currentEditingHost.type = BooruType(rawValue: sender.selectedTag())!;
        save();
    }
    
    @IBOutlet weak var postsPerPageTextField: NSTextField!
    @IBAction func postsPerPageTextField(_ sender: NSTextField) {
        currentEditingHost.pagePostLimit = sender.integerValue;
        save();
    }
    
    @IBOutlet weak var maximumRatingPopUpButton: NSPopUpButton!
    @IBAction func maximumRatingPopUpButton(_ sender: NSPopUpButton) {
        currentEditingHost.maximumRating = Rating(rawValue: sender.selectedTag())!;
        save();
    }
    
    @IBOutlet weak var removeButton: NSButton!
    @IBAction func removeButton(_ sender: NSButton) {
        // Don't allow the user to have zero hosts
        if(preferences.booruHosts.count > 1) {
            preferences.booruHosts.remove(at: tableView.selectedRow);
            tableView.reloadData();
            save();
        }
    }
    
    @IBOutlet weak var addButton: NSButton!
    @IBAction func addButton(_ sender: NSButton) {
        preferences.booruHosts.append(BooruHost(name: "Name", type: BooruType.moebooru, pagePostLimit: 40, url: "URL", maximumRating: Rating.explicit));
        
        tableView.reloadData();
        tableView.deselectAll(self);
        tableView.selectRowIndexes(IndexSet(integer: preferences.booruHosts.count - 1), byExtendingSelection: false);
        
        save();
    }
    
    @IBOutlet weak var clearDownloadHistoryButton: NSButton!
    @IBAction func clearDownloadHistoryButton(_ sender: Any) {
        currentEditingHost.downloadedPosts = [];
        save();
    }
    
    @IBOutlet weak var clearTagHistoryButton: NSButton!
    @IBAction func clearTagHistoryButton(_ sender: NSButton) {
        currentEditingHost.tagHistory = [];
        save();
    }
    
    @IBOutlet weak var tagBlacklistTokenField: NSTokenField!
    @IBAction func tagBlacklistTokenField(_ sender: NSTokenField) {
        currentEditingHost.tagBlacklist = sender.tokens;
        save();
    }
    
    var currentEditingHost : BooruHost = BooruHost();
    
    var preferences : Preferences {
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
    
    func displayInfo(from host : BooruHost) {
        currentEditingHost = host;
        
        postsPerPageTextField.integerValue = host.pagePostLimit;
        typePopUpButton.selectItem(withTag: host.type.rawValue);
        maximumRatingPopUpButton.selectItem(withTag: host.maximumRating.rawValue);
        
        tagBlacklistTokenField.stringValue = "";
        for(_, currentTag) in host.tagBlacklist.enumerated() {
            tagBlacklistTokenField.addToken(currentTag);
        }
    }
    
    /// Called when the user changes the name of a Booru list item
    @objc func booruNameTextFieldEdited(_ sender: NSTextField) {
        print("PreferencesBoorusViewController: Changing name of \"\(currentEditingHost.name)\" to \"\(sender.stringValue)\"");
        
        preferences.booruHosts[sender.tag].name = sender.stringValue;
        save();
    }
    
    
    /// Called when the user changes the URL of a Booru list item
    @objc func booruUrlTextFieldEdited(_ sender: NSTextField) {
        print("PreferencesBoorusViewController: Changing URL of \"\(currentEditingHost.name)\" to \"\(sender.stringValue)\"");
        
        // Guarantee a trailing slash on the URL
        if(!sender.stringValue.hasSuffix("/")) {
            sender.stringValue = sender.stringValue + "/";
        }
        
        preferences.booruHosts[sender.tag].url = sender.stringValue;
        save();
    }
    
    private func load() {
        currentEditingHost = preferences.booruHosts[0];
        displayInfo(from: currentEditingHost);
    }
    
    private func save() {
        currentEditingHost.refreshUtilities();
        NotificationCenter.default.post(name: Notification.Name(rawValue: "Preferences.Updated"), object: nil);
    }
}

extension PreferencesBoorusController: NSTableViewDataSource {
    func numberOfRows(in aTableView: NSTableView) -> Int {
        return preferences.booruHosts.count;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView: NSTableCellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as! NSTableCellView;
        let cellData : BooruHost = preferences.booruHosts[row];
        
        cellView.textField?.tag = row;
        
        if(tableColumn!.identifier.rawValue == "names") {
            cellView.textField?.stringValue = cellData.name;
            
            cellView.textField?.target = self;
            cellView.textField?.action = #selector(PreferencesBoorusController.booruNameTextFieldEdited(_:));
            
            return cellView;
        }
        else if(tableColumn!.identifier.rawValue == "urls") {
            cellView.textField?.stringValue = cellData.url;
            
            cellView.textField?.target = self;
            cellView.textField?.action = #selector(PreferencesBoorusController.booruUrlTextFieldEdited(_:));
            
            return cellView;
        }
        
        // Return the unmodified cell view, we dont need to do anything
        return cellView;
    }
}

extension PreferencesBoorusController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow : Int = (notification.object as! NSTableView).selectedRow;
        currentEditingHost.tagBlacklist = tagBlacklistTokenField.tokens;
        displayInfo(from: preferences.booruHosts[selectedRow]);
    }
}
