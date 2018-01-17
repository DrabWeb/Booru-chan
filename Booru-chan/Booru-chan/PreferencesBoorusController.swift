//
//  PreferencesBoorusController.swift
//  Booru-chan
//
//  Created by Ushio on 2/3/17.
//

import Cocoa

class PreferencesBoorusController: NSViewController {

    private var currentEditingHost: BooruHost!

    private var preferences: Preferences {
        return (NSApp.delegate as! AppDelegate).preferences;
    }
    
    @IBOutlet weak var booruTableView: NSTableView!
    @IBOutlet weak var typePopUpButton: NSPopUpButton!
    @IBOutlet weak var removeButton: NSButton!
    @IBOutlet weak var postsPerPageTextField: NSTextField!
    @IBOutlet weak var maximumRatingPopUpButton: NSPopUpButton!
    @IBOutlet weak var tagBlacklistTokenField: NSTokenField!

    @IBAction func removeSelectedBooru(_ sender: NSButton) {
        let row = booruTableView.selectedRow;

        preferences.booruHosts.remove(at: row);
        booruTableView.reloadData();
        booruTableView.selectRowIndexes([min(row, preferences.booruHosts.count - 1)], byExtendingSelection: false);
        updateRemoveButton();

        save();
    }

    @IBAction func addNewBooru(_ sender: NSButton) {
        preferences.booruHosts.append(BooruHost(name: "Name", type: BooruType.moebooru, pagePostLimit: 40, url: "http://new.booru/url/", maximumRating: .explicit));
        
        booruTableView.reloadData();
        booruTableView.deselectAll(self);
        booruTableView.selectRowIndexes(IndexSet(integer: preferences.booruHosts.count - 1), byExtendingSelection: false);

        updateRemoveButton();
        save();
    }

    @IBAction func clearDownloadHistory(_ sender: Any) {
        //clear download history
        save();
    }

    @IBAction func clearTagHistory(_ sender: NSButton) {
        currentEditingHost.tagHistory = [];
        save();
    }

    @IBAction func applyChanges(_ sender: Any!) {
        currentEditingHost.type = BooruType(rawValue: typePopUpButton.selectedTag())!;
        currentEditingHost.pagePostLimit = postsPerPageTextField.integerValue;
        currentEditingHost.maximumRating = Rating(rawValue: maximumRatingPopUpButton.selectedTag())!;
        currentEditingHost.tagBlacklist = tagBlacklistTokenField.tokens.map { Tag(name: $0) };

        save();
    }

    @IBAction func booruNameEdited(_ sender: NSTextField!) {
        print("PreferencesBoorusController: Changing name of \"\(currentEditingHost.name)\" to \"\(sender.stringValue)\"");

        preferences.booruHosts[sender.tag].name = sender.stringValue;
        save();
    }

    @IBAction func booruUrlEdited(_ sender: NSTextField!) {
        if !sender.stringValue.hasSuffix("/") {
            sender.stringValue = "\(sender.stringValue)/";
        }

        print("PreferencesBoorusController: Changing URL of \"\(currentEditingHost.name)\" to \"\(sender.stringValue)\"");

        preferences.booruHosts[sender.tag].url = sender.stringValue;
        save();
    }
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        load();
        updateRemoveButton();
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear();
        save();
    }
    
    private func edit(host: BooruHost) {
        currentEditingHost = host;
        
        postsPerPageTextField.integerValue = host.pagePostLimit;
        typePopUpButton.selectItem(withTag: host.type.rawValue);
        maximumRatingPopUpButton.selectItem(withTag: host.maximumRating.rawValue);
        
        tagBlacklistTokenField.stringValue = "";
        for (_, currentTag) in host.tagBlacklist.enumerated() {
            tagBlacklistTokenField.addToken(currentTag.name);
        }
    }

    private func load() {
        currentEditingHost = preferences.booruHosts[0];
        edit(host: currentEditingHost);
    }

    private func save() {
        currentEditingHost.refreshUtilities();
        NotificationCenter.default.post(name: Notification.Name(rawValue: "Preferences.Updated"), object: nil);
    }

    private func updateRemoveButton() {
        removeButton.isEnabled = preferences.booruHosts.count > 1;
    }
}

extension PreferencesBoorusController: NSTableViewDataSource {
    func numberOfRows(in aTableView: NSTableView) -> Int {
        return preferences.booruHosts.count;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as! NSTableCellView;
        let cellData = preferences.booruHosts[row];
        let t = cellView.textField!;

        t.tag = row;

        switch tableColumn!.identifier.rawValue {
            case "Name":
                t.stringValue = cellData.name;
                return cellView;
            case "URL":
                t.stringValue = cellData.url;
                return cellView;
            default:
                return cellView;
        }
    }
}

extension PreferencesBoorusController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = (notification.object as! NSTableView).selectedRow;
        edit(host: preferences.booruHosts[selectedRow]);
    }
}
