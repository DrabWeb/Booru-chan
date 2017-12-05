//
//  TagListTableViewCell.swift
//  Booru-chan
//
//  Created by Seth on 2016-05-03.
//

import Cocoa

class TagListTableViewCell: NSTableCellView {
    /// The data this item represents
    var data : TagListTableViewData = TagListTableViewData();
    
    /// The checkbox button for this cell
    @IBOutlet var checkbox: NSButton!
    
    /// The object to perform changedAction
    var changedTarget : AnyObject? = nil;
    
    /// The selector to call when the checkbox is pressed
    var changedAction : Selector? = nil;
    
    /// When we press checkbox...
    @IBAction func checkboxPressed(_ sender: AnyObject) {
        // If changedTarget and changedAction arent nil...
        if(changedTarget != nil && changedAction != nil) {
            // Perform the selector with this cells data and the new state
            _ = changedTarget!.perform(changedAction!, with: [data : Bool(truncating: checkbox.state as NSNumber)]);
        }
    }
}
