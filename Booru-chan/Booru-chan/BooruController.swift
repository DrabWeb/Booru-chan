//
//  BooruController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class BooruController: NSSplitViewController, IThemeable {

    private var window: NSWindow!

    private var lastBooru: BooruHost!
    private var currentBooru: BooruHost! {
        didSet {
            if currentBooru == lastBooru {
                return;
            }

            lastBooru = currentBooru;
            browserController.postsController.items = [];
            selectedPosts = [];

            //todo: temporary
            _ = currentBooru.utilties!.getPostsFromSearch("", limit: 40, page: 1, completionHandler: { self.browserController.postsController.items = $0 });
        }
    }

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

    @IBAction func booruChanged(_ sender: NSPopUpButton) {
        currentBooru = (NSApp.delegate as! AppDelegate).preferences.booruHosts[sender.indexOfSelectedItem];
    }

    private var selectedPosts: [BooruPost] = [] {
        didSet {
            let i = browserController.infoBarController;

            if selectedPosts.count == 1 {
                let p = selectedPosts.first!;

                i.imageSize = p.imageSize;
                i.rating = p.rating;
                browserController.tagListController.tags = p.tags;
                viewerController.display(post: p, progressHandler: { progress in
                    i.loadingProgress = progress;
                });
            }
            else {
                i.imageSize = nil;
                i.rating = nil;
                i.loadingProgress = nil;
                browserController.tagListController.tags = [];
                viewerController.display(post: nil);
            }
        }
    }

    func applyTheme(theme: Theme) {
        window.appearance = theme.appearance;
        browserController.applyTheme(theme: theme);
    }

    override func viewDidLoad() {
        super.viewDidLoad();

        window = NSApp.windows.last!;
        browserController.postsController.onSelect = { self.selectedPosts = $0 };
        browserController.postsController.onReachedBottom = {
            if self.browserController.postsController.items.count > 0 {
                _ = self.currentBooru.utilties!.getPostsFromSearch(self.currentBooru.utilties!.lastSearch,
                                                                   limit: self.currentBooru.utilties!.lastSearchLimit,
                                                                   page: self.currentBooru.utilties!.lastSearchPage + 1,
                                                                   completionHandler: { self.browserController.postsController.items.append(contentsOf: $0) });
            }
        };

        //todo: load theme properly from the preferences
        applyTheme(theme: .light);
    }
}
