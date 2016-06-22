//
//  BCGridStyleTagListTableViewCellView.swift
//  Booru-chan
//
//  Created by Seth on 2016-05-03.
//

import Cocoa

class BCGridStyleTagListTableViewCellView: NSTableCellView {
    /// The data this item represents
    var data : BCGridStyleTagListTableViewItemData = BCGridStyleTagListTableViewItemData();
    
    /// The checkbox button for this cell
    @IBOutlet var checkbox: NSButton!
    
    /// The object to perform changedAction
    var changedTarget : AnyObject? = nil;
    
    /// The selector to call when the checkbox is pressed
    var changedAction : Selector? = nil;
    
    /// When we press checkbox...
    @IBAction func checkboxPressed(sender: AnyObject) {
        // If changedTarget and changedAction arent nil...
        if(changedTarget != nil && changedAction != nil) {
            // Perform the selector with this cells data and the new state
            changedTarget!.performSelector(changedAction!, withObject: [data : Bool(checkbox.state)]);
        }
    }
}