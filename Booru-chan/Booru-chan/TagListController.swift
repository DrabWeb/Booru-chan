//
//  TagListController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class TagListController: NSViewController {

    @IBOutlet private weak var tagsTableView: NSTableView!

    var onTagChecked: ((String) -> Void)?
    var onTagUnchecked: ((String) -> Void)?

    // called by every tag cell, decides the initial state of the checkbox, true = on, false = off
    var getTagState: ((String) -> Bool) = { tag in
        return false;
    };

    var tags: [String] = [] {
        didSet {
            tagsTableView.reloadData();
        }
    }

    @IBAction func tagToggled(_ sender: NSButton!) {
        let t = tags[sender.tag];

        switch sender.state {
            case .on:
                onTagChecked?(t);
                break;
            case .off:
                onTagUnchecked?(t);
                break;
            default:
                break;
        }
    }
}

extension TagListController: NSTableViewDataSource {
    func numberOfRows(in aTableView: NSTableView) -> Int {
        return tags.count;
    }
}

extension TagListController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TagCell"), owner: nil) as? TagListCellView {
            let t = tags[row];
            cell.tagNameCheckbox.title = t;
            cell.tagNameCheckbox.state = getTagState(t) ? .on : .off;
            cell.tagNameCheckbox.tag = row;
            return cell;
        }

        return nil;
    }
}
