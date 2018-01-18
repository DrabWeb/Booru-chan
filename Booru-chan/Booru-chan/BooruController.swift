//
//  BooruController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa
import Alamofire

class BooruController: NSSplitViewController, IThemeable {

    private var window: NSWindow!
    private var lastBooru: BooruHost!
    private var lastSearchRequest: Request?

    //todo: fix a bug where the status bar is broken when changing boorus while an image is loading
    private var currentBooru: BooruHost! {
        didSet {
            if currentBooru == lastBooru {
                return;
            }

            lastBooru = currentBooru;
            (self.window.windowController as! BooruWindowController).searchField.changeSuggestionsBooru(to: currentBooru);
            clear();
        }
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

    @IBAction func searchQueryEntered(_ sender: NSSearchField!) {
        //todo: find some way to make the action only fire when pressing enter, not when cleared
        self.window.makeFirstResponder(self);
        search(for: sender.stringValue);
    }

    func search(for query: String) {
        lastSearchRequest?.cancel();
        lastSearchRequest = currentBooru.utilties.getPostsFromSearch(query,
                                                                     limit: currentBooru.pagePostLimit,
                                                                     page: 1,
                                                                     completionHandler: {
                                                                         self.browserController.postsController.items = $0;
                                                                         self.browserController.postsController.scrollToTop();
                                                                     });
    }

    func applyTheme(theme: Theme) {
        window.appearance = theme.appearance;
        browserController.applyTheme(theme: theme);
    }

    private func clear() {
        browserController.postsController.items = [];
        selectedPosts = [];
    }

    override func viewDidLoad() {
        super.viewDidLoad();

        //todo: dont allow more pages to load when there is already one loading
        //todo: add some way to tell if theres any more results

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
