//
//  BCRasterizedViews.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-24.
//

import Cocoa

class BCRasterizedImageView: NSImageView {

    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        // Drawing code here.
        // Rasterize the layer
        self.layer?.shouldRasterize = true;
    }
}
