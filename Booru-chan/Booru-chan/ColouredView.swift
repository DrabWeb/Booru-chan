//
//  ColouredView.swift
//  Booru-chan
//
//  Created by Ushio on 2016-04-23.
//

import Cocoa

class ColouredView: NSView {

    var colour: NSColor = NSColor.clear;

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        self.wantsLayer = true;
        self.layer?.backgroundColor = colour.cgColor;
    }
}
