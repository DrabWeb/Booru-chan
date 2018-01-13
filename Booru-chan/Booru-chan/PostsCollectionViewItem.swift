//
//  PostsCollectionViewItem.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa
import Alamofire

class PostsCollectionViewItem: NSCollectionViewItem {

    @IBOutlet private weak var selectionBox: BooruCollectionViewSelectionBox!

    private var request: ImageDownloader?

    var representedPost: BooruPost? {
        didSet {
            guard isViewLoaded else {
                return;
            }

            request = ImageDownloader(url: URL(string: representedPost!.thumbnailUrl)!);
            request!.download(complete: { image in
                self.imageView!.image = image;
                self.view.layer!.shouldRasterize = true;
            });
        }
    }

    override var isSelected: Bool {
        didSet {
            selectionBox.isHidden = !isSelected;
        }
    }

    deinit {
        request?.cancel();
    }
}


