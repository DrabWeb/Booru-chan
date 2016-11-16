//
//  BCColoredView.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//

import Cocoa

class BCColoredView: NSView {
    
    /// The background color of the view
    var backgroundColor : NSColor = NSColor.clear;

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        // Make sure we get a layer
        self.wantsLayer = true;
        
        // Set the layer's background color
        self.layer?.backgroundColor = backgroundColor.cgColor;
    }
}
