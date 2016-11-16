//
//  BCAlwaysActiveTextField.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//

import Cocoa

class BCAlwaysActiveTextField: NSTextField {

    // Override acceptsFirstResponder so it is always in the active graphical state
    override var acceptsFirstResponder : Bool {
        return true;
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}

class BCAlwaysActiveTokenField: NSTokenField {
    
    // Override acceptsFirstResponder so it is always in the active graphical state
    override var acceptsFirstResponder : Bool {
        return true;
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
}
