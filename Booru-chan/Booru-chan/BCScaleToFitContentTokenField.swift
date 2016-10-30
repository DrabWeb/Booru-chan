//
//  BCScaleToFitContentTokenField.swift
//  Booru-chan
//
//  Created by Seth on 2016-10-29.
//

import Cocoa

class BCScaleToFitContentTokenField: NSTokenField {
    
    override var intrinsicContentSize : NSSize {
        /// The intrinsic size to return, set as the size of this token field fit to the super view's width
        var size : NSSize = self.sizeThatFits(NSSize(width: self.superview!.frame.width, height: self.superview!.frame.height));
        size = NSSize(width: self.superview!.frame.width, height: size.height);
        
        // Return the size
        return size;
    }
    
    /// Calls invalidateIntrinsicContentSize
    func updateToFitContent() {
        // Re-calculate the intrinsic content size
        self.invalidateIntrinsicContentSize();
    }
    
    override func textDidChange(notification: NSNotification) {
        super.textDidChange(notification);
        
        // Update the size of this token field
        updateToFitContent();
    }
    
    override func viewWillDraw() {
        super.viewWillDraw();
        
        // Update the size of this token field
        updateToFitContent();
    }
    
    override func awakeFromNib() {
        super.awakeFromNib();
        
        // Update the size of this token field
        updateToFitContent();
    }
}