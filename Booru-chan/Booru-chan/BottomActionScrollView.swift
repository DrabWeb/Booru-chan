//
//  BottomActionScrollView.swift
//  Booru-chan
//
//  Created by Ushio on 2016-04-25.
//

import Cocoa

class BottomActionScrollView: NSScrollView {

    fileprivate var atBottom: Bool = false;
    
    var onReachedBottom: (() -> Void)?
    
    override func reflectScrolledClipView(_ cView: NSClipView) {
        super.reflectScrolledClipView(cView);

        if self.documentView!.frame.height <= (self.documentVisibleRect.height + self.documentVisibleRect.origin.y) {
            if !atBottom {
                onReachedBottom?();
            }

            atBottom = true;
        }
        else {
            atBottom = false;
        }
    }
}
