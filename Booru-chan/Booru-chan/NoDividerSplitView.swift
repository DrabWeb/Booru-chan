//
//  NoDividerSplitView.swift
//  Booru-chan
//
//  Created by Ushio on 2016-04-23.
//

import Cocoa

class NoDividerSplitView: NSSplitView {
    
    // Override the divider thickness to 0
    override var dividerThickness : CGFloat {
        return 0;
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
}
