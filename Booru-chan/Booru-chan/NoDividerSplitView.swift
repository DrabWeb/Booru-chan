//
//  NoDividerSplitView.swift
//  Booru-chan
//
//  Created by Ushio on 2016-04-23.
//

import Cocoa

class NoDividerSplitView: NSSplitView {
    override var dividerThickness: CGFloat {
        return 0;
    }
}
