//
//  BCBooruCollectionViewCollectionViewItem.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-24.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa

class BCBooruCollectionViewCollectionViewItem: NSCollectionViewItem {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Bind the alpha value
        self.imageView?.bind("alphaValue", toObject: self, withKeyPath: "representedObject.alphaValue", options: nil);
    }
}
