//
//  SidebarDoc.swift
//  Booru-chan
//
//  Created by Seth on 2015-11-01.
//  Copyright © 2015 DrabWeb. All rights reserved.
//

import Foundation
import Cocoa
import AppKit

class SidebarDoc: NSObject {
    var thumbnailImage: NSImage!;
    
    init(thumbnailImage: NSImage!) {
        self.thumbnailImage = thumbnailImage!;
    }
}
