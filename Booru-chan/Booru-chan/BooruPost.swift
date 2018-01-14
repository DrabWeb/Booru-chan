//
//  BooruPost.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-14.
//

import Foundation

class BooruPost {

    var id: Int = -1;
    var url: String = "";
    var tags: [String] = [];
    var rating: Rating = .none;

    var thumbnailUrl: String = "";
    var thumbnailSize: NSSize = NSSize.zero;

    var imageUrl: String = "";
    var imageSize: NSSize = NSSize.zero;

    var animated: Bool {
        return imageUrl.lowercased().hasSuffix(".gif");
    }
}
