//
//  ViewerController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa
import Alamofire

class ViewerController: NSViewController {

    private var thumbnailRequest: ImageDownloader?
    private var request: ImageDownloader?

    @IBOutlet private weak var imageView: NSImageView!

    func displayPost(post: BooruPost?, progressHandler: ((Double) -> Void)?) {
        thumbnailRequest?.cancel();
        request?.cancel();

        if post == nil {
            return;
        }

        thumbnailRequest = ImageDownloader(url: URL(string: post!.thumbnailUrl)!);
        thumbnailRequest?.download(complete: { thumbnail in
            self.imageView.image = thumbnail;
        });

        request = ImageDownloader(url: URL(string: post!.imageUrl)!);
        request?.download(progress: { progress in
            progressHandler?(progress);
        }, complete: { image in
            self.thumbnailRequest?.cancel();
            self.imageView.image = image;
        });
    }
}
