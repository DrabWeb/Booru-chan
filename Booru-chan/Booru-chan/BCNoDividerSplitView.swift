//
//  BCNoDividerSplitView.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//

import Cocoa

class BCNoDividerSplitView: NSSplitView {
    
    // Override the divider thickness to 0
    override var dividerThickness : CGFloat {
        return 0;
    }

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
    }
}
