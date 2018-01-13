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

    private var request: Request?

    var representedPost: BooruPost? {
        didSet {
            guard isViewLoaded else {
                return;
            }

            request = Alamofire.request(representedPost!.thumbnailUrl)
                .responseData { r in
                    if (r.response?.statusCode ?? -1) != 200 {
                        self.imageView!.image = NSImage(named: NSImage.Name.caution);
                        self.imageView!.toolTip = "Status code " + String(r.response?.statusCode ?? -1);
                        return;
                    };

                    if let d = r.result.value {
                        if let image = NSImage(data: d) {
                            self.imageView!.image = image;
                            self.view.layer!.shouldRasterize = true;
                        }
                    }
                }
        }
    }

    override var isSelected: Bool {
        didSet {
            selectionBox.isHidden = !isSelected;
        }
    }
}


