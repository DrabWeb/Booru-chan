//
//  RasterizedImageView.swift
//  Booru-chan
//
//  Created by Ushio on 2016-04-24.
//

import Cocoa

class RasterizedImageView: NSImageView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.layer?.shouldRasterize = true;
    }
}
