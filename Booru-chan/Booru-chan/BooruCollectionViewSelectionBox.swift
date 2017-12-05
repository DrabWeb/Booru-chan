//
//  BooruCollectionViewSelectionBox.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-24.
//

import Cocoa

class BooruCollectionViewSelectionBox: NSBox {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect);
        
        self.boxType = NSBox.BoxType.custom;
        self.cornerRadius = 5;
        
        // Cheaty way to check if the view is light/dark, because NSCompositeAppearance is private
        var light : Bool = false;
        for (_, appearance) in (effectiveAppearance.value(forKey: "appearances") as! [NSAppearance]).enumerated() {
            if(appearance.name.rawValue == "NSAppearanceNameVibrantLight") {
                light = true;
            }
        }
        
        self.alphaValue = light ? 0.1 : 0.2;
        self.fillColor = NSColor.black;
        self.borderType = NSBorderType.noBorder;
    }
}
