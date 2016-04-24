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
    
    /// Searches for the given string and returns the results as and array of BCBooruPosts
    func getPostsFromSearch(search : String, limit : Int, page : Int, completionHandler: ([BCBooruPost]) -> ()) {
        /// The search results to pass to the completion handler
        var results : [BCBooruPost] = [];
        
        // Perform the search and get the results
        // Depending on which Booru API we are using...
        if(type == .Moebooru) {
            // Make the get request to the Booru with the post ID...
            Alamofire.request(.GET, (baseUrl + "/post.json?tags=" + search + "&page=" + String(page) + "&limit=" + String(limit)).stringByReplacingOccurrencesOfString(" ", withString: "%20"), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // For every search result...
                    for(_, currentResult) in responseJson.enumerate() {
                        // Add the current post to the results
                        results.append(self.getPostFromData(currentResult.1, xml: nil)!);
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        else if(type == .DanbooruLegacy) {
            // Make the get request to the Booru with the post ID...
            Alamofire.request(.GET, (baseUrl + "/post/index.json?tags=" + search + "&page=" + String(page) + "&limit=" + String(limit)).stringByReplacingOccurrencesOfString(" ", withString: "%20"), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // For every search result...
                    for(_, currentResult) in responseJson.enumerate() {
                        // Add the current post to the results
                        results.append(self.getPostFromData(currentResult.1, xml: nil)!);
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        else if(type == .Danbooru) {
            // Make the get request to the Booru with the post ID...
            Alamofire.request(.GET, (baseUrl + "/posts.json?tags=" + search + "&page=" + String(page) + "&limit=" + String(limit)).stringByReplacingOccurrencesOfString(" ", withString: "%20"), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // For every search result...
                    for(_, currentResult) in responseJson.enumerate() {
                        // Add the current post to the results
                        results.append(self.getPostFromData(currentResult.1, xml: nil)!);
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        else if(type == .Gelbooru) {
            // Make the get request to the Booru with the post ID...
            Alamofire.request(.GET, (baseUrl + "/index.php?page=dapi&s=post&q=index&tags=" + search + "&pid=" + String(page) + "&limit=" + String(limit)).stringByReplacingOccurrencesOfString(" ", withString: "%20"), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The XML from the response string
                    let responseXml = SWXMLHash.parse(dataFromResponseJsonString);
                    
                    // For every search result...
                    for(_, currentResult) in responseXml["posts"].children.enumerate() {
                        // Add the current post to the results
                        results.append(self.getPostFromData(nil, xml: currentResult)!);
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
    }
    
    /// Gets the post at the given ID and returns a BCBooruPost(Can be nil)
    func getPostFromId(id : Int, completionHandler: (BCBooruPost?) -> ()) {
        // Get the post
        // Depending on which Booru API we are using...
        if(type == .Moebooru) {
            // Make the get request to the Booru with the post ID...
            Alamofire.request(.GET, baseUrl + "/post.json?tags=id:" + String(id), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // Return the post from the JSON we got
                    completionHandler(self.getPostFromData(responseJson[0], xml: nil));
                }
            }
        }
        else if(type == .DanbooruLegacy) {
            // Make the get request to the Booru with the post ID...
            Alamofire.request(.GET, baseUrl + "/post/index.json?tags=id:" + String(id), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // Return the post from the JSON we got
                    completionHandler(self.getPostFromData(responseJson[0], xml: nil));
                }
            }
        }
        else if(type == .Danbooru) {
            // Make the get request to the Booru with the post ID...
            Alamofire.request(.GET, baseUrl + "/posts.json?tags=id:" + String(id), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // Return the post from the JSON we got
                    completionHandler(self.getPostFromData(responseJson[0], xml: nil));
                }
            }
        }
        else if(type == .Gelbooru) {
            // Make the get request to the Booru with the post ID...
            Alamofire.request(.GET, baseUrl + "/index.php?page=dapi&s=post&q=index&tags=id:" + String(id), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The XML from the response string
                    let responseXml = SWXMLHash.parse(dataFromResponseJsonString);
                    
                    // If there is a first element in the posts children...
                    if(responseXml["posts"].children.count > 0) {
                        // Return the post from the XML we got
                        completionHandler(self.getPostFromData(nil, xml: responseXml["posts"].children[0]));
                    }
                }
            }
        }
    }
    
    func getPostFromData(json : JSON?, xml : XMLIndexer?) -> BCBooruPost? {
        /// The post to return
        var post : BCBooruPost? = nil;
        
        // Get the post
        // Depending on which Booru API we are using...
        if(type == .Moebooru) {
            // Make post a new BCBooruPost
            post = BCBooruPost();
            
            // Set the post's info
            post?.thumbnailUrl = json!["preview_url"].stringValue;
            post?.thumbnailSize = NSSize(width: json!["actual_preview_width"].intValue, height: json!["actual_preview_height"].intValue);
            
            post?.imageUrl = json!["jpeg_url"].stringValue;
            post?.imageSize = NSSize(width: json!["jpeg_width"].intValue, height: json!["jpeg_height"].intValue);
            
            switch(json!["rating"]) {
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
                    print("Rating for post \(json!["id"])(\(json!["rating"])) is invalid");
                    break;
            }
            
            post?.tags = json!["tags"].stringValue.componentsSeparatedByString(" ");
            
            post?.url = self.baseUrl + "/post/show/\(json!["id"])";
        }
        else if(type == .DanbooruLegacy) {
            // Make post a new BCBooruPost
            post = BCBooruPost();
            
            // Set the post's info
            post?.thumbnailUrl = baseUrl + json!["preview_url"].stringValue;
            
            // Danbooru doesnt give you a thumbnail size
            post?.thumbnailSize = NSSize.zero;
            
            post?.imageUrl = baseUrl + json!["file_url"].stringValue;
            post?.imageSize = NSSize(width: json!["width"].intValue, height: json!["height"].intValue);
            
            switch(json!["rating"]) {
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
                    print("Rating for post \(json!["id"])(\(json!["rating"])) is invalid");
                    break;
            }
            
            post?.tags = json!["tags"].stringValue.componentsSeparatedByString(" ");
            
            // For some reason the tags attribute on Gelbooru always starts with a space, and it creates a empty tag as the first element in the tags array. Check if it exists, and if it does, remove it(Also try with the last, just in case)
            if(post?.tags[0] == "") {
                post?.tags.removeFirst();
            }
            if(post?.tags[(post?.tags.count)! - 1] == "") {
                post?.tags.removeLast();
            }
            
            post?.url = self.baseUrl + "/posts/\(json!["id"])";
        }
        else if(type == .Danbooru) {
            // Make post a new BCBooruPost
            post = BCBooruPost();
            
            // Set the post's info
            post?.thumbnailUrl = baseUrl + json!["preview_file_url"].stringValue;
            
            // Danbooru doesnt give you a thumbnail size
            post?.thumbnailSize = NSSize.zero;
            
            post?.imageUrl = baseUrl + json!["large_file_url"].stringValue;
            post?.imageSize = NSSize(width: json!["image_width"].intValue, height: json!["image_height"].intValue);
            
            switch(json!["rating"]) {
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
                print("Rating for post \(json!["id"])(\(json!["rating"])) is invalid");
                break;
            }
            
            post?.tags = json!["tag_string_artist"].stringValue.componentsSeparatedByString(" ");
            post?.tags.appendContentsOf(json!["tag_string_character"].stringValue.componentsSeparatedByString(" "));
            post?.tags.appendContentsOf(json!["tag_string_copyright"].stringValue.componentsSeparatedByString(" "));
            post?.tags.appendContentsOf(json!["tag_string_general"].stringValue.componentsSeparatedByString(" "));
            
            post?.url = self.baseUrl + "/posts/\(json!["id"])";
        }
        else if(type == .Gelbooru) {
            // Make post a new BCBooruPost
            post = BCBooruPost();
            
            // Set the post's info
            post?.thumbnailUrl = xml!.element!.attributes["preview_url"]!;
            post?.thumbnailSize = NSSize(width: NSString(string: xml!.element!.attributes["preview_width"]!).integerValue, height: NSString(string: xml!.element!.attributes["preview_height"]!).integerValue);
            
            post?.imageUrl = xml!.element!.attributes["file_url"]!;
            post?.imageSize = NSSize(width: NSString(string: xml!.element!.attributes["width"]!).integerValue, height: NSString(string: xml!.element!.attributes["height"]!).integerValue);
            
            switch(xml!.element!.attributes["rating"]!) {
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
                    print("Rating for post \(xml!.element!.attributes["id"]!)(\(xml!.element!.attributes["rating"]!)) is invalid");
                    break;
            }
            
            post?.tags = xml!.element!.attributes["tags"]!.componentsSeparatedByString(" ");
            
            // For some reason the tags attribute on Gelbooru always starts with a space, and it creates a empty tag as the first element in the tags array. Check if it exists, and if it does, remove it(And it also does the same with the last)
            if(post?.tags[0] == "") {
                post?.tags.removeFirst();
            }
            if(post?.tags[(post?.tags.count)! - 1] == "") {
                post?.tags.removeLast();
            }
            
            post?.url = self.baseUrl + "/index.php?page=post&s=view&id=\(xml!.element!.attributes["id"]!)";
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

class BCBooruHost {
    /// The display name of this Booru
    var name : String = "";
    
    /// What type of Booru this is
    var type : BCBooruType = .Unchosen;
    
    /// The URL to this Booru
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