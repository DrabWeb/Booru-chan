//
//  PostsCollectionViewSelectionBox.swift
//  Booru-chan
//
//  Created by Ushio on 2016-04-24.
//

import Cocoa

class PostsCollectionViewSelectionBox: NSBox {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect);
        
        self.boxType = NSBox.BoxType.custom;
        self.cornerRadius = 5;

        var light = false;

        // check if this view has a light or dark appearance
        for (_, appearance) in (effectiveAppearance.value(forKey: "appearances") as! [NSAppearance]).enumerated() {
            if appearance.name.rawValue == "NSAppearanceNameVibrantLight" {
                light = true;
            }
        }
        
        self.alphaValue = light ? 0.1 : 0.2;
        self.fillColor = NSColor.black;
        self.borderType = NSBorderType.noBorder;
    }
}
