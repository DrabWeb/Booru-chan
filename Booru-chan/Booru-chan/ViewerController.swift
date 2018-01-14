//
//  ViewerController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa
import Alamofire

class ViewerController: NSViewController {

    private var thumbnailDownloader: ImageDownloader?
    private var imageDownloader: ImageDownloader?

    @IBOutlet private weak var imageView: NSImageView!

    //todo: fix bug where a blank thumbnail is displayed when switching posts while the image is loading
    func display(post: BooruPost?, progressHandler: ((Double) -> Void)? = nil) {
        thumbnailDownloader?.cancel();
        imageDownloader?.cancel();

        if post == nil {
            imageView.image = nil;
            return;
        }

        thumbnailDownloader = ImageDownloader(url: URL(string: post!.thumbnailUrl)!);
        thumbnailDownloader?.download(complete: { thumbnail in
            self.imageView.image = thumbnail;
        });

        imageDownloader = ImageDownloader(url: URL(string: post!.imageUrl)!);
        imageDownloader?.download(progress: { progress in
            progressHandler?(progress);
        }, complete: { image in
            self.thumbnailDownloader?.cancel();
            self.imageView.image = image;
        });
    }
}
