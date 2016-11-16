//
//  BCBooruCollectionViewSelectionBox.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-24.
//

import Cocoa

class BCBooruCollectionViewSelectionBox: NSBox {

    override func awakeFromNib() {
        // Set it to be a custom box
        self.boxType = NSBoxType.custom;
        
        // Set the corner radius to 5
        self.cornerRadius = 5;
        
        // Set the alpha value to 0.2
        self.alphaValue = 0.2;
        
        // Set the box to have no border
        self.borderType = NSBorderType.noBorder;
        
        // Set the background color to black
        self.fillColor = NSColor.black;
    }
}
