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

    private var selectedPosts: [BooruPost] = [] {
        didSet {
            let i = browserController.infoBarController;

            if selectedPosts.count == 1 {
                let p = selectedPosts.first!;

                i.imageSize = p.imageSize;
                i.rating = p.rating;
                viewerController.displayPost(post: p, progressHandler: { progress in
                    i.loadingProgress = progress;
                });
            }
            else {
                i.imageSize = nil;
                i.rating = nil;
                i.loadingProgress = nil;
                viewerController.displayPost(post: nil, progressHandler: nil);
            }
        }
    }

    func applyTheme(theme: Theme) {
        window.appearance = theme.appearance;

        browserController.applyTheme(theme: theme);
    }

    let booru = BooruHost(name: "Danbooru", type: .danbooru, pagePostLimit: 40, url: "http://danbooru.donmai.us/", maximumRating: .explicit);
    override func viewDidLoad() {
        super.viewDidLoad();

        window = NSApp.windows.last!;
        browserController.postsController.onSelect = { self.selectedPosts = $0 };
        applyTheme(theme: .light);

        let utils = BooruUtilities(booru: booru);
        _ = utils.getPostsFromSearch("", limit: 40, page: 1, completionHandler: { self.browserController.postsController.items = $0 });
    }
}
