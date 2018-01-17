//
//  TagListController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class TagListController: NSViewController {

    @IBOutlet private weak var tagsTableView: NSTableView!

    private var internalTags: [TagCell] = [];

    var onTagChecked: ((Tag) -> Void)?
    var onTagUnchecked: ((Tag) -> Void)?

    // called by every tag cell, decides the initial state of the checkbox, true = on, false = off
    var getTagState: ((Tag) -> Bool) = { tag in
        return false;
    };

    var tags: [Tag] = [] {
        didSet {
            internalTags.removeAll();
            tags.forEach { tag in
                if !internalTags.contains(where: { $0.tag.type == tag.type }) {
                    internalTags.append(TagCellHeader(tag: Tag(type: tag.type)));
                }

                internalTags.append(TagCell(tag: tag));
            };

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

    private class TagCell {
        let tag: Tag;

        init(tag: Tag) {
            self.tag = tag;
        }
    }

    private class TagCellHeader: TagCell {

    }
}

extension TagListController: NSTableViewDataSource {
    func numberOfRows(in aTableView: NSTableView) -> Int {
        return internalTags.count;
    }
}

extension TagListController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellData = internalTags[row];

        if cellData is TagCellHeader {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: nil) as? NSTableCellView {
                cell.textField!.stringValue = "\(cellData.tag.type)".capitalized;
                return cell;
            }
        }
        else {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "TagCell"), owner: nil) as? TagListCellView {
                let t = cellData.tag;
                let typeBullet = "● ";
                let title = NSMutableAttributedString(string: typeBullet + t.name.replacingOccurrences(of: "_", with: " "));
                title.addAttributes([.foregroundColor: t.type.representedColour()], range: NSMakeRange(0, typeBullet.count));

                cell.tagNameCheckbox.attributedTitle = title;
                cell.tagNameCheckbox.state = getTagState(t) ? .on : .off;
                cell.tagNameCheckbox.tag = row;
                return cell;
            }
        }

        return nil;
    }
}
