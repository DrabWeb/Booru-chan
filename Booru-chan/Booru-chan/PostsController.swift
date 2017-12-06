//
//  PostsController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class PostsController: NSViewController {
    @IBOutlet private weak var scrollView: BottomActionScrollView!
    @IBOutlet private weak var collectionView: NSCollectionView!

    var items: [BooruPost] = [] {
        didSet {
            collectionView.reloadData();
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad();

        for _ in 0..<50 {
            items.append(BooruPost());
        }
    }
}

extension PostsController: NSCollectionViewDataSource {
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 1;
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count;
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PostsCollectionViewItem"), for: indexPath);
        guard let collectionViewItem = item as? PostsCollectionViewItem else {
            return item;
        }

        collectionViewItem.representedPost = items[indexPath.item];
        return item;
    }
}
