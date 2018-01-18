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

    var onSelect: (([BooruPost]) -> Void)?
    var onReachedBottom: (() -> Void)? { //todo: fix a bug where onReachedBottom is spammed if the view is resized when the user is at the bottom
        didSet {
            scrollView.onReachedBottom = onReachedBottom;
        }
    }

    func scrollToTop() {
        scrollView.documentView!.scroll(NSPoint(x: 0, y: -scrollView.contentInsets.top));
    }

    private func sendOnSelect() {
        onSelect?(collectionView.selectionIndexes.map { items[$0] });
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

extension PostsController: NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        sendOnSelect();
    }

    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        sendOnSelect();
    }
}
