//
//  BooruTitlebarView.swift
//  Booru-chan
//
//  Created by Ushio on 12/4/16.
//

import Cocoa

class BooruTitlebarView: NSVisualEffectView {

    // Cancel out the mouse triggering views behind the titlebar
    
    override func mouseDown(with event: NSEvent) {
        // Do nothing
    }
    
    override func mouseDragged(with event: NSEvent) {
        // Drag the window with the drag event
        self.window?.performDrag(with: event);
    }
}
