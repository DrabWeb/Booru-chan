//
//  BooruPost.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-14.
//

import Foundation

/// A post made on a Booru
class BooruPost {
    /// The URL to this post's thumbnail image
    var thumbnailUrl : String = "";

    /// The size(In pixels) of the thumbnail image
    var thumbnailSize : NSSize = NSSize.zero;

    /// The URL to this post's full size image
    var imageUrl : String = "";

    /// The size(In pixels) of the full size image
    var imageSize : NSSize = NSSize.zero;

    /// The tags on this post
    var tags : [String] = [];

    /// The rating of this post
    var rating : Rating = Rating.safe;

    /// The ID of this post
    var id : Int = -1;

    /// The URL to this post on it's respective Booru
    var url : String = "";

    /// Is this post's image animated?
    var animated : Bool {
        // Return if the extension is GIF
        return (NSString(string: self.imageUrl).pathExtension.lowercased() == "gif");
    }
}
