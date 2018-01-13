//
//  ViewerController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class ViewerController: NSViewController {
    @IBOutlet private weak var imageView: NSImageView!

    func displayPost(post: BooruPost?, progressHandler: ((Double) -> Void)?) {
        if post == nil {
            imageView.image = nil;
            return;
        }
    }
}
