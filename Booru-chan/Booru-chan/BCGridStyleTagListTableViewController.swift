//
//  BCGridStyleTagListTableViewController.swift
//  Booru-chan
//
//  Created by Seth on 2016-05-03.
//

import Cocoa

class BCGridStyleTagListTableViewController: NSObject {
    /// A reference to the main view controller
    @IBOutlet weak var mainViewController: BCViewController!
    
    /// The tag list items to show in the tag list table view
    var tagListItems : [BCGridStyleTagListTableViewItemData] = [];
    
    /// The scroll view for tagsTableView
    @IBOutlet weak var tagsTableViewScrollView: NSScrollView!
    
    /// The table view for displaying the tags on the current selected posts
    @IBOutlet weak var tagsTableView: NSTableView!
    
    /// The last post passed to displayTagsFromPost
    var lastDisplayedPost : BCBooruPost = BCBooruPost();
    
    /// Displays the tags from the given post in the tags table view
    func displayTagsFromPost(_ post: BCBooruPost) {
        // Clear all the current items
        tagListItems.removeAll();
        
        // For every one of the post's tags...
        for(_, currentTag) in post.tags.enumerated() {
            /// Is this tag already being searched by?
            var tagBeingSearchedBy : Bool = false;
            
            // If the search field has the current tag in it's tokens...
            if(mainViewController.toolbarSearchField.tokens.contains(currentTag)) {
                // Say we are searching by this tag
                tagBeingSearchedBy = true;
            }
            
            // Add the current tag to the tags table view
            tagListItems.append(BCGridStyleTagListTableViewItemData(tagName: currentTag, tagBeingSearchedBy: tagBeingSearchedBy));
        }
        
        // Reload the tags table view
        tagsTableView.reloadData();
        
        // If we arent just refreshing the tag list...
        if(lastDisplayedPost.url != post.url) {
            // Scroll to the top of the tag list
            tagsTableView.scrollRowToVisible(0);
        }
        
        // Set lastDisplayedPost to post
        lastDisplayedPost = post;
    }
    
    /// Called when the user presses a checkbox in the tag list
    @objc func tagListItemChanged(_ data: [BCGridStyleTagListTableViewItemData : Bool]) {
        /// The BCGridStyleTagListTableViewItemData from data
        var changedData : BCGridStyleTagListTableViewItemData = BCGridStyleTagListTableViewItemData();
        
        /// The state we changed to for the tag
        var changedState : Bool = false;
        
        // Load in the data into their respective variables
        for(_, currentData) in data.enumerated() {
            changedData = currentData.0;
            changedState = currentData.1;
        }
        
        // Update the data
        changedData.tagBeingSearchedBy = changedState;
        
        // If we now want to add the tag to the search...
        if(changedState) {
            // Print what we are doing
            print("BCGridStyleController: Adding \"\(changedData.tagName)\" to the search field");
            
            // Add the given token to the search field
            mainViewController.toolbarSearchField.addToken(changedData.tagName);
        }
        // If we now want to remove the tag from the search...
        else {
            // Print what we are doing
            print("BCGridStyleController: Removing \"\(changedData.tagName)\" from the search field");
            
            // Remove the given token from the search field
            mainViewController.toolbarSearchField.removeToken(changedData.tagName);
        }
    }
}

extension BCGridStyleTagListTableViewController: NSTableViewDataSource {
    func numberOfRows(in aTableView: NSTableView) -> Int {
        // Return the amount of items in tagListItems
        return self.tagListItems.count;
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        /// The cell view for the cell we want to modify
        let cellView: NSTableCellView = tableView.makeView(withIdentifier: tableColumn!.identifier, owner: nil) as! NSTableCellView;
        
        // If this is the main column...
        if(tableColumn!.identifier.rawValue == "Main Column") {
            /// cellView as a BCGridStyleTagListTableViewCellView
            let cellViewTagListCellView : BCGridStyleTagListTableViewCellView = cellView as! BCGridStyleTagListTableViewCellView;
            
            /// The data for this cell
            let cellData : BCGridStyleTagListTableViewItemData = tagListItems[row];
            
            // Set the cell's data and display it
            cellViewTagListCellView.data = cellData;
            cellViewTagListCellView.checkbox.state = NSControl.StateValue(rawValue: Int.fromBool(bool: cellData.tagBeingSearchedBy));
            cellViewTagListCellView.checkbox.title = cellData.tagName;
            
            // Setup the target and action
            cellViewTagListCellView.changedTarget = self;
            cellViewTagListCellView.changedAction = #selector(BCGridStyleTagListTableViewController.tagListItemChanged(_:));
            
            // Return the modified cell view
            return cellViewTagListCellView as NSTableCellView;
        }
        
        // Return the unmodified cell view, we dont need to do anything
        return cellView;
    }
}

extension BCGridStyleTagListTableViewController: NSTableViewDelegate {
    
}
