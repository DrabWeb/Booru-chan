//
//  SuggestionsController.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Cocoa
import Alamofire

class SuggestionsController: NSViewController {

    @IBOutlet private weak var suggestionsTableView: SuggestionsTableView!
    @IBOutlet private weak var suggestionsScrollView: NSScrollView!

    private var internalItems: [SuggestionCell] = [];
    private var lastSuggestionsRequest: Request?

    var showHistory: Bool = false;

    // passed the current filter
    var getSuggestions: ((String, @escaping ([Tag]) -> Void) -> Request?)?
    var onSelectSuggestion: ((String?) -> Void)?
    var onClickSuggestion: ((SuggestionItem) -> Void)?
    var onItemsChange: ((Bool) -> Void)?

    var favouriteTags: [String] = [];
    var searchHistory: [String] = [];

    var filter: String = "" {
        didSet {
            updateSuggestions();
        }
    }

    var items: [SuggestionItem] = [] {
        didSet {
            updateInternalItems();
            suggestionsTableView.reloadData();
            updatePreferredSize();
        }
    }

    var selectedItem: SuggestionItem? {
        get {
            if suggestionsTableView.selectedRow == -1 {
                return nil;
            }

            return internalItems[suggestionsTableView.selectedRow].item;
        }
    }

    var hasResults: Bool {
        get {
            return !internalItems.isEmpty;
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad();

        suggestionsTableView.onClick = { row in
            self.onClickSuggestion?(self.internalItems[row].item);
        };
    }

    func updateSuggestions() {
        lastSuggestionsRequest?.cancel();
        var newItems: [SuggestionItem] = [];

        func addMatches(from values: [String], title: String, maximum: Int) {
            let matches = (values.filter { $0.hasPrefix(filter) && $0 != filter }).prefix(maximum);
            if matches.isEmpty {
                return;
            }

            newItems.append(SuggestionSection(title: title, items: matches.map { SuggestionItem(title: $0) }));
        }

        addMatches(from: favouriteTags, title: "Favourites", maximum: 5);
        if showHistory { addMatches(from: searchHistory, title: "History", maximum: 5); }
        if !filter.isEmpty {
            lastSuggestionsRequest = getSuggestions?(filter, { suggestions in
                if !suggestions.isEmpty {
                    self.items.append(SuggestionSection(title: "Suggestions", items: suggestions.map { SuggestionTag(tag: $0) }));
                }
            });
        };

        items = newItems;
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

        onItemsChange?(hasResults);
    }

    private func updatePreferredSize() {
        self.preferredContentSize = NSSize(width: self.view.frame.width,
                                           height: NSMaxY(suggestionsTableView.rect(ofRow: suggestionsTableView.numberOfRows - 1)) +
                                                          suggestionsScrollView.contentInsets.top +
                                                          suggestionsScrollView.contentInsets.bottom -
                                                          CGFloat(internalItems.filter { $0 is SuggestionDividerCell }.count * 10)); //dividers arent already accounted for, do it manually
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
            // deselect all if the user tries to select the row above the last selectable row
            if i >= 0 && i < tableView.selectedRow {
                if internalItems[0..<i].filter({ !$0.isSelectable }).isEmpty {
                    tableView.deselectAll(self);
                    return [];
                }
            }

            if !internalItems[i].isSelectable {
                return [];
            }
        }

        return proposedSelectionIndexes;
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellData = internalItems[row];
        var identifier = "ContentCell";
        if cellData is SuggestionHeaderCell {
            identifier = "HeaderCell";
        }
        else if cellData is SuggestionDividerCell {
            identifier = "DividerCell";
        }
        else if cellData.item is SuggestionTag {
            identifier = "TagCell";
        }

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier), owner: nil) as? NSTableCellView {
            if let i = cellData.item as? SuggestionTag, let tagCell = cell as? SuggestionsTagCellView {
                tagCell.representedTag = i.tag;
                return tagCell;
            }
            else {
                cell.textField?.stringValue = cellData.item.title;
            }

            return cell;
        }

        return nil;
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        if suggestionsTableView.selectedRow > -1 {
            onSelectSuggestion?(internalItems[suggestionsTableView.selectedRow].item.title);
        }
        else {
            onSelectSuggestion?(nil);
        }
    }
}
