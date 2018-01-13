//
//  BrowserController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class BrowserController: NSSplitViewController, IThemeable {
    @IBOutlet private weak var postsItem: NSSplitViewItem!
    var postsController: PostsController {
        get {
            return postsItem.viewController as! PostsController;
        }
    }

    @IBOutlet private weak var infoBarItem: NSSplitViewItem!
    var infoBarController: InfoBarController {
        get {
            return infoBarItem.viewController as! InfoBarController;
        }
    }

    @IBOutlet private weak var tagListItem: NSSplitViewItem!
    var tagListController: TagListController {
        get {
            return tagListItem.viewController as! TagListController;
        }
    }

    func applyTheme(theme: Theme) {

    }
}
