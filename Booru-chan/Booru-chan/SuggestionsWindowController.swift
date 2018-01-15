//
//  SuggestionsWindowController.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Cocoa

class SuggestionsWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad();

        self.window!.standardWindowButton(.closeButton)!.superview!.superview!.removeFromSuperview();
        self.window!.isMovable = false;
    }
}

class SuggestionsWindow: NSPanel {
    override var canBecomeKey: Bool {
        return false;
    }
}
