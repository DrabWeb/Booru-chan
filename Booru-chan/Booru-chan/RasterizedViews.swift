//
//  RasterizedViews.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-24.
//

import Cocoa

class RasterizedImageView: NSImageView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
        // Rasterize the layer
        self.layer?.shouldRasterize = true;
    }
}
