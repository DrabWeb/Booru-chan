//
//  BooruController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class BooruController: NSSplitViewController {
    @IBOutlet private weak var browserItem: NSSplitViewItem!
    private var browserController: BrowserController {
        get {
            return browserItem.viewController as! BrowserController;
        }
    }

    @IBOutlet weak var viewerItem: NSSplitViewItem!
    private var viewerController: ViewerController {
        get {
            return viewerItem.viewController as! ViewerController;
        }
    }
}
