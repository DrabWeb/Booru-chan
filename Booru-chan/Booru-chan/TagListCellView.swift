//
//  TagListCellView.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-14.
//

import Cocoa

class TagListCellView: NSTableCellView {
    @IBOutlet weak var tagNameCheckbox: NSButton!

    override func mouseDown(with event: NSEvent) {
        tagNameCheckbox.mouseDown(with: event);
    }
}
