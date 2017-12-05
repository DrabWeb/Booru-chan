//
//  BooruController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class BooruController: NSSplitViewController, IThemeable {
    private var window: NSWindow!

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

    func applyTheme(theme: Theme) {
        window.appearance = theme.appearance;

        browserController.applyTheme(theme: theme);
    }

    override func viewDidLoad() {
        super.viewDidLoad();

        window = NSApp.windows.last!;
        applyTheme(theme: .light);
    }
}
