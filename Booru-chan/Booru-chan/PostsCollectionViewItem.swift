//
//  PostsCollectionViewItem.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa
import Alamofire

class PostsCollectionViewItem: NSCollectionViewItem {

    @IBOutlet private weak var selectionBox: PostsCollectionViewSelectionBox!

    private var downloader: ImageDownloader?

    var representedPost: BooruPost? {
        didSet {
            guard isViewLoaded else {
                return;
            }

            downloader = ImageDownloader(url: URL(string: representedPost!.thumbnailUrl)!);
            downloader!.download(complete: { image in
                self.imageView!.image = image;
            });
        }
    }

    override var isSelected: Bool {
        didSet {
            selectionBox.isHidden = !isSelected;
        }
    }

    override func prepareForReuse() {
        downloader?.cancel();
        self.imageView!.image = nil;
        self.selectionBox.isHidden = true;
    }

    deinit {
        downloader?.cancel();
    }
}


