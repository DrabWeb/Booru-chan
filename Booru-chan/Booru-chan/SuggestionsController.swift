//
//  SuggestionsController.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Cocoa

class SuggestionsController: NSViewController {
    @IBOutlet weak var suggestionsTableView: NSTableView!

    var items: [SuggestionItem] = [] {
        didSet {
            suggestionsTableView.reloadData();
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad();

        items = [SuggestionSection(title: "Favourites and History"),
                 SuggestionItem(title: "These"),
                 SuggestionItem(title: "Are"),
                 SuggestionDivider(),
                 SuggestionSection(title: "Suggestions"),
                 SuggestionItem(title: "Example"),
                 SuggestionItem(title: "Items")];
    }
}

extension SuggestionsController: NSTableViewDataSource {
    func numberOfRows(in aTableView: NSTableView) -> Int {
        return items.count;
    }
}

extension SuggestionsController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        if let i = proposedSelectionIndexes.first {
            if items[i] is SuggestionSection || items[i] is SuggestionDivider {
                return [];
            }
        }

        return proposedSelectionIndexes;
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellData = items[row];
        let identifier = cellData is SuggestionSection ? "HeaderCell" : cellData is SuggestionDivider ? "DividerCell" : "ContentCell";

        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = items[row].title;
            return cell;
        }

        return nil;
    }
}
