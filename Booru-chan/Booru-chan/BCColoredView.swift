//
//  BCColoredView.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//

import Cocoa

class BCColoredView: NSView {
    
    /// The background color of the view
    var backgroundColor : NSColor = NSColor.clearColor();

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)

        // Drawing code here.
        // Make sure we get a layer
        self.wantsLayer = true;
        
        // Set the layer's background color
        self.layer?.backgroundColor = backgroundColor.CGColor;
    }
}
