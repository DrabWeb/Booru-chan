//
//  PostsCollectionViewItem.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class PostsCollectionViewItem: NSCollectionViewItem {
    @IBOutlet private weak var selectionBox: BooruCollectionViewSelectionBox!

    var representedPost: BooruPost? {
        didSet {
            guard isViewLoaded else {
                return;
            }
        }
    }

    override var isSelected: Bool {
        didSet {
            selectionBox.isHidden = !isSelected;
        }
    }
}


