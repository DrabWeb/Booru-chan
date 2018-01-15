//
//  SuggestionsController.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Cocoa

class SuggestionsController: NSViewController {

    @IBOutlet private weak var suggestionsTableView: HoverSelectTableView!
    @IBOutlet private weak var suggestionsScrollView: NSScrollView!

    private var internalItems: [SuggestionCell] = [];

    var items: [SuggestionItem] = [] {
        didSet {
            updateInternalItems();
            suggestionsTableView.reloadData();
            updateWindowSize();
        }
    }

    private func updateInternalItems() {
        internalItems.removeAll();

        for (_, item) in items.enumerated() {
            if item is SuggestionSection {
                internalItems.append(SuggestionHeaderCell(item: item));
                for (_, childItem) in (item as! SuggestionSection).items.enumerated() {
                    internalItems.append(SuggestionCell(item: childItem));
                }

                internalItems.append(SuggestionDividerCell());
            }
        }

        if internalItems.last is SuggestionDividerCell {
            internalItems.removeLast();
        }
    }

    private func updateWindowSize() {
        self.preferredContentSize = NSSize(width: self.view.frame.width,
                                           height: NSMaxY(suggestionsTableView.rect(ofRow: suggestionsTableView.numberOfRows - 1)) +
                                                          suggestionsScrollView.contentInsets.top +
                                                          suggestionsScrollView.contentInsets.bottom);
    }

    private class SuggestionCell {
        let item: SuggestionItem!

        var isSelectable: Bool {
            return true;
        }

        init(item: SuggestionItem!) {
            self.item = item;
        }
    }

    private class SuggestionHeaderCell: SuggestionCell {
        override var isSelectable: Bool {
            return false;
        }
    }

    private class SuggestionDividerCell: SuggestionCell {
        override var isSelectable: Bool {
            return false;
        }

        init() {
            super.init(item: nil);
        }
    }
}

extension SuggestionsController: NSTableViewDataSource {
    func numberOfRows(in aTableView: NSTableView) -> Int {
        return internalItems.count;
    }
}

extension SuggestionsController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        if let i = proposedSelectionIndexes.first {
            if !internalItems[i].isSelectable {
                return [];
            }
        }

        return proposedSelectionIndexes;
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellData = internalItems[row];
        let identifier = cellData is SuggestionHeaderCell ? "HeaderCell" : cellData is SuggestionDividerCell ? "DividerCell" : "ContentCell";

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = cellData.item.title;
            return cell;
        }

        return nil;
    }
}
