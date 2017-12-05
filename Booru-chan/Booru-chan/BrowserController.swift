//
//  BrowserController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class BrowserController: NSSplitViewController {
    @IBOutlet weak var postsItem: NSSplitViewItem!
    private var postsController: PostsController {
        get {
            return postsItem.viewController as! PostsController;
        }
    }

    @IBOutlet weak var infoBarItem: NSSplitViewItem!
    private var infoBarController: InfoBarController {
        get {
            return infoBarItem.viewController as! InfoBarController;
        }
    }

    @IBOutlet weak var tagListItem: NSSplitViewItem!
    private var tagListController: TagListController {
        get {
            return tagListItem.viewController as! TagListController;
        }
    }
}
