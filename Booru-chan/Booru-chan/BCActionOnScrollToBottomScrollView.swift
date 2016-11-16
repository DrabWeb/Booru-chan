//
//  BCActionOnScrollToBottomScrollView.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-25.
//

import Cocoa
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}


class BCActionOnScrollToBottomScrollView: NSScrollView {
    
    /// Are we at the bottom of the scroll view?(Used so it isnt spammed when reaching the bottom)
    fileprivate var atBottom : Bool = false;
    
    /// The object to perform reachedBottomAction
    var reachedBottomTarget : AnyObject? = nil;
    
    /// The selector to call when the user reaches the bottom of this scroll view
    var reachedBottomAction : Selector? = nil;
    
    override func reflectScrolledClipView(_ cView: NSClipView) {
        super.reflectScrolledClipView(cView);
        
        // If we are at the bottom of the scroll view...
        if(self.documentView?.frame.height <= ((self.documentVisibleRect.height + self.documentVisibleRect.origin.y))) {
            // If we havent already called the bottom reached action...
            if(!atBottom) {
                // If reachedBottomTarget and reachedBottomAction are both not nil...
                if(reachedBottomTarget != nil && reachedBottomAction != nil) {
                    // Call the reached bottom action
                    reachedBottomTarget!.perform(reachedBottomAction!);
                }
            }
            
            // Say we are at the bottom
            atBottom = true;
        }
        // If we arent at the bottom of the scroll view
        else {
            // Say we arent at the bottom
            atBottom = false;
        }
    }
}
