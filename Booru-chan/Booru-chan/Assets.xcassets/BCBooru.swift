//
//  BCBooru.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftyJSON
import SWXMLHash

class BCBooruUtilities {
    /// The type of Booru to use for this Booru Utilities
    var type : BCBooruType = .Unchosen;
    
    /// The base URL of this Booru(Without a trailing slash)
    var baseUrl : String = "";
    
    /// Gets the post at the given ID and returns a BCBooruPost(Can be nil)
    func getPost(id : Int, completionHandler: (BCBooruPost?) -> ()) -> BCBooruPost? {
        // Return the output of getPostRequest with the given values
        return getPostRequest(id, completionHandler: completionHandler);
    }
    
    /// Makes the actual request for getPost
    func getPostRequest(id : Int, completionHandler: (BCBooruPost?) -> ()) -> BCBooruPost? {
        /// The post for the given ID
        var post : BCBooruPost? = nil;
        
        // Get the post
        // Depending on which Booru API we are using...
        if(type == .Moebooru) {
            // https://yande.re/post.json?tags=id:$ID
            // Make the get request to the Booru with the post ID...
            Alamofire.request(.GET, baseUrl + "/post.json?tags=id:" + String(id), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // Make post a new BCBooruPost
                    post = BCBooruPost();
                    
                    // Set the post's info
                    post?.thumbnailUrl = responseJson[0]["preview_url"].stringValue;
                    post?.thumbnailSize = NSSize(width: responseJson[0]["actual_preview_width"].intValue, height: responseJson[0]["actual_preview_height"].intValue);
                    
                    post?.imageUrl = responseJson[0]["jpeg_url"].stringValue;
                    post?.imageSize = NSSize(width: responseJson[0]["jpeg_width"].intValue, height: responseJson[0]["jpeg_height"].intValue);
                    
                    switch(responseJson[0]["rating"]) {
                    case "s":
                        post?.rating = .Safe;
                        break;
                    case "q":
                        post?.rating = .Questionable;
                        break;
                    case "e":
                        post?.rating = .Explicit;
                        break;
                    default:
                        print("Rating for post \(id)(\(responseJson[0]["rating"])) is invalid");
                        break;
                    }
                    
                    post?.tags = responseJson[0]["tags"].stringValue.componentsSeparatedByString(" ");
                    
                    post?.url = "http://yande.re/post/\(id)/show";
                    
                    // Return the post
                    completionHandler(post);
                }
            }
        }
        else if(type == .DanbooruLegacy) {
            
        }
        else if(type == .Danbooru) {
            
        }
        else if(type == .Gelbooru) {
            
        }
        
        // Return the post
        return post;
    }
}

/// A post made on a Booru
class BCBooruPost {
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
    var rating : BCRating = BCRating.Safe;
    
    /// The URL to this post on it's respective Booru
    var url : String = "";
}

/// The different types of Booru Booru-chan can use
enum BCBooruType {
    /// Used for placeholders/variable initiation
    case Unchosen
    
    /// Moebooru
    case Moebooru
    
    /// Danbooru 1.x
    case DanbooruLegacy
    
    /// Danbooru 2.x
    case Danbooru
    
    /// Gelbooru
    case Gelbooru
}

/// The different ratings a post can have
enum BCRating {
    /// Safe
    case Safe
    
    /// Questionable(Red face)
    case Questionable
    
    /// Explicit(L-lewd...)
    case Explicit
}