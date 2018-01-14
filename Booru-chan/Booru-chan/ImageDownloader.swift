//
//  ImageDownloader.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-13.
//

import Foundation
import Alamofire

class ImageDownloader {

    private let url: URL!

    private var request: Request?

    init(url: URL) {
        self.url = url;
    }

    func download(progress: ((Double) -> Void)? = nil, complete: @escaping (NSImage?) -> Void) {
        cancel();
        request = Alamofire.request(url)
            .downloadProgress { p in
                progress?(p.fractionCompleted);
            }
            .responseData { r in
                if let d = r.result.value {
                    if let image = NSImage(data: d) {
                        complete(image);
                        return;
                    }
                }

                complete(nil);
            }
    }

    func cancel() {
        request?.cancel();
    }
}
