//
//  BCBooru.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//

import Cocoa
import Alamofire
import SwiftyJSON
import SWXMLHash

class BCBooruUtilities {
    /// The BCBooruHost this booru utilities represents
    weak var representedBooru : BCBooruHost? = nil;
    
    /// The type of Booru to use for this Booru Utilities
    var type : BCBooruType = .unchosen;
    
    /// The base URL of this Booru(Without a trailing slash)
    var baseUrl : String = "";
    
    /// The last search string
    var lastSearch : String = "";
    
    /// The limit of the last search
    var lastSearchLimit : Int = -1;
    
    /// The page of the last search
    var lastSearchPage = -1;
    
    /// The maximum rating of post to show when searching
    var maximumRating : BCRating = .explicit;
    
    /// Returns an array of Strings containing all the tags that matched the passed query(You can do things like *query, query* and *query*)
    func getTagsMatchingSearch(_ search : String, completionHandler: @escaping ([String]) -> ()) -> Request? {
        // Print what we are searching for
        print("BCBooruUtilities: Searching for tags matching \"\(search)\" on \"\(self.baseUrl)\"");
        
        /// The request that will be made, and then returned
        var request : Request? = nil;
        
        /// The tag search results to pass to the completion handler
        var results : [String] = [];
        
        // Get the tags with the passed query
        // Depending on which Booru API we are using...
        if(type == .moebooru) {
            // baseUrl/tag.json?name=search
            // Print what URL we are using
            print("BCBooruUtilities: Using URL \((baseUrl + "/tag.json?name=" + search + "&limit=0")) to search for tags");
            
            // Make the request to get the tags
            request = Alamofire.request((baseUrl + "/tag.json?name=" + search + "&limit=0").replacingOccurrences(of: " ", with: "%20")).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // For evert tag in responseJson...
                    for(_, currentTag) in responseJson.enumerated() {
                        // Add the current tag's name to the results
                        results.append(currentTag.1["name"].stringValue);
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        else if(type == .danbooru || type == .danbooruLegacy) {
            /// baseUrl/tags.json?search[name_matches]=search
            // Print what URL we are using
            print("BCBooruUtilities: Using URL \((baseUrl + "/tags.json?search[name_matches]=" + search + "&limit=1000")) to search for tags");
            
            // Make the request to get the tags(It seems Danbooru has a tag request limit of 1000(Using 0 gives you none), so I use 1000 here)
            request = Alamofire.request((baseUrl + "/tags.json?search[name_matches]=" + search + "&limit=1000").replacingOccurrences(of: " ", with: "%20")).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // For evert tag in responseJson...
                    for(_, currentTag) in responseJson.enumerated() {
                        // Add the current tag's name to the results
                        results.append(currentTag.1["name"].stringValue);
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        else if(type == .gelbooru) {
            // There is no proper API for getting tags with the format "*search", "search*" or "*search*"(Or at least froom what I can find), so do nothing
        }
        
        // Return the request
        return request;
    }
    
    /// Searches for the given string and returns the results as and array of BCBooruPosts
    func getPostsFromSearch(_ search : String, limit : Int, page : Int, completionHandler: @escaping ([BCBooruPost]) -> ()) -> Request? {
        // Print what we are searching for
        print("BCBooruUtilities: Searching for \"\(search)\"(Limit \(limit), page \(page)) on \"\(self.baseUrl)\"");
        
        /// The search results to pass to the completion handler
        var results : [BCBooruPost] = [];
        
        /// The request that will be made, and then returned
        var request : Request? = nil;
        
        /// The string to append to the search query to set the maximum rating of posts to show
        var ratingLimitString : String = "";
        
        // If the maximum rating isnt Explicit...
        if(maximumRating != .explicit) {
            // If the maximum rating is Safe...
            if(maximumRating == .safe) {
                // Set rating limit string to " rating:safe"
                ratingLimitString = " rating:safe";
            }
            // If the maximum rating is Questionable...
            else if(maximumRating == .questionable) {
                // Set rating limit string to " -rating:explicit"
                ratingLimitString = " -rating:explicit";
            }
        }
        
        // Perform the search and get the results
        // Depending on which Booru API we are using...
        if(type == .moebooru) {
            /// The URL to make the search request to
            var requestUrl : String = (baseUrl + "/post.json?tags=" + search + ratingLimitString + "&page=" + String(page) + "&limit=" + String(limit));
            
            // Encode special characters in the request URL
            requestUrl = requestUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
            
            // Print what URL we are querying
            print("BCBooruUtilities: Using URL \"\(requestUrl)\" to search");
            
            // Make the get request to the Booru with the search string and rating limit...
            request = Alamofire.request(requestUrl).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // For every search result...
                    for(_, currentResult) in responseJson.enumerated() {
                        /// The BCBooruPost from currentResult
                        let post : BCBooruPost = self.getPostFromData(json: currentResult.1, xml: nil)!;
                        
                        /// Does the current post have a blacklisted tag?
                        var containsTagInBlacklist : Bool = false;
                        
                        // If the tag blacklist isn't empty(don't want to waste time when there's no possibility)...
                        if(self.representedBooru!.tagBlacklist.count > 0) {
                            // For every tag in the current post's tag...
                            for(_, currentTag) in post.tags.enumerated() {
                                // If the current tag is in the tag blacklist...
                                if(self.representedBooru!.tagBlacklist.contains(currentTag)) {
                                    // Say there was a blacklisted tag in this item
                                    containsTagInBlacklist = true;
                                    
                                    // Print that this post was blacklisted
                                    print("BCBooruUtilities: Blacklisted post \(post.id) from \(self.representedBooru!.name) for tag \"\(currentTag)\"");
                                    
                                    // Stop the loop
                                    break;
                                }
                            }
                        }
                        
                        // If this post isn't blacklisted...
                        if(!containsTagInBlacklist) {
                            // Add the current post to the results
                            results.append(post);
                        }
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        else if(type == .danbooruLegacy) {
            /// The URL to make the search request to
            var requestUrl : String = (baseUrl + "/post/index.xml?page=\(page)&limit=\(limit)&tags=\(search + ratingLimitString)");
            
            // Encode special characters in the request URL
            requestUrl = requestUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
            
            // Print what URL we are querying
            print("BCBooruUtilities: Using URL \"\(requestUrl)\" to search");
            
            // Make the get request to the Booru with the search string and rating limit...
            request = Alamofire.request(requestUrl).response { (responseData) -> Void in
                /// The string of XML that will be returned when the GET request finishes
                let responseXmlString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseXmlString = responseXmlString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The XML from the response string
                    let responseXml = SWXMLHash.parse(dataFromResponseXmlString);
                    
                    // For every search result...
                    for(_, currentResult) in responseXml["posts"].children.enumerated() {
                        /// The BCBooruPost from currentResult
                        let post : BCBooruPost = self.getPostFromData(json: nil, xml: currentResult)!;
                        
                        /// Does the current post have a blacklisted tag?
                        var containsTagInBlacklist : Bool = false;
                        
                        // If the tag blacklist isn't empty(don't want to waste time when there's no possibility)...
                        if(self.representedBooru!.tagBlacklist.count > 0) {
                            // For every tag in the current post's tag...
                            for(_, currentTag) in post.tags.enumerated() {
                                // If the current tag is in the tag blacklist...
                                if(self.representedBooru!.tagBlacklist.contains(currentTag)) {
                                    // Say there was a blacklisted tag in this item
                                    containsTagInBlacklist = true;
                                    
                                    // Print that this post was blacklisted
                                    print("BCBooruUtilities: Blacklisted post \(post.id) from \(self.representedBooru!.name) for tag \"\(currentTag)\"");
                                    
                                    // Stop the loop
                                    break;
                                }
                            }
                        }
                        
                        // If this post isn't blacklisted...
                        if(!containsTagInBlacklist) {
                            // Add the current post to the results
                            results.append(post);
                        }
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        else if(type == .danbooru) {
            /// The URL to make the search request to
            var requestUrl : String = (baseUrl + "/posts.json?tags=" + search + ratingLimitString + "&page=" + String(page) + "&limit=" + String(limit));
            
            // Encode special characters in the request URL
            requestUrl = requestUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
            
            // Print what URL we are querying
            print("BCBooruUtilities: Using URL \"\(requestUrl)\" to search");
            
            // Make the get request to the Booru with the search string and rating limit...
            request = Alamofire.request(requestUrl).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // For every search result...
                    for(_, currentResult) in responseJson.enumerated() {
                        /// The BCBooruPost from currentResult
                        let post : BCBooruPost = self.getPostFromData(json: currentResult.1, xml: nil)!;
                        
                        print(currentResult.1);
                        
                        /// Does the current post have a blacklisted tag?
                        var containsTagInBlacklist : Bool = false;
                        
                        // If the tag blacklist isn't empty(don't want to waste time when there's no possibility)...
                        if(self.representedBooru!.tagBlacklist.count > 0) {
                            // For every tag in the current post's tag...
                            for(_, currentTag) in post.tags.enumerated() {
                                // If the current tag is in the tag blacklist...
                                if(self.representedBooru!.tagBlacklist.contains(currentTag)) {
                                    // Say there was a blacklisted tag in this item
                                    containsTagInBlacklist = true;
                                    
                                    // Print that this post was blacklisted
                                    print("BCBooruUtilities: Blacklisted post \(post.id) from \(self.representedBooru!.name) for tag \"\(currentTag)\"");
                                    
                                    // Stop the loop
                                    break;
                                }
                            }
                        }
                        
                        // If this post isn't blacklisted...
                        if(!containsTagInBlacklist) {
                            // Add the current post to the results
                            results.append(post);
                        }
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        else if(type == .gelbooru) {
            /// The URL to make the search request to
            var requestUrl : String = (baseUrl + "/index.php?page=dapi&s=post&q=index&tags=" + search + ratingLimitString + ratingLimitString + "&pid=" + String(page - 1) + "&limit=" + String(limit));
            
            // Encode special characters in the request URL
            requestUrl = requestUrl.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
            
            // Print what URL we are querying
            print("BCBooruUtilities: Using URL \"\(requestUrl)\" to search");
            
            // Make the get request to the Booru with the search string and rating limit...
            request = Alamofire.request(requestUrl).response { (responseData) -> Void in
                /// The string of XML that will be returned when the GET request finishes
                let responseXmlString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseXmlString = responseXmlString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The XML from the response string
                    let responseXml = SWXMLHash.parse(dataFromResponseXmlString);
                    
                    // For every search result...
                    for(_, currentResult) in responseXml["posts"].children.enumerated() {
                        /// The BCBooruPost from currentResult
                        let post : BCBooruPost = self.getPostFromData(json: nil, xml: currentResult)!;
                        
                        /// Does the current post have a blacklisted tag?
                        var containsTagInBlacklist : Bool = false;
                        
                        // If the tag blacklist isn't empty(don't want to waste time when there's no possibility)...
                        if(self.representedBooru!.tagBlacklist.count > 0) {
                            // For every tag in the current post's tag...
                            for(_, currentTag) in post.tags.enumerated() {
                                // If the current tag is in the tag blacklist...
                                if(self.representedBooru!.tagBlacklist.contains(currentTag)) {
                                    // Say there was a blacklisted tag in this item
                                    containsTagInBlacklist = true;
                                    
                                    // Print that this post was blacklisted
                                    print("BCBooruUtilities: Blacklisted post \(post.id) from \(self.representedBooru!.name) for tag \"\(currentTag)\"");
                                    
                                    // Stop the loop
                                    break;
                                }
                            }
                        }
                        
                        // If this post isn't blacklisted...
                        if(!containsTagInBlacklist) {
                            // Add the current post to the results
                            results.append(post);
                        }
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        
        // Set the last search string, page and limit
        lastSearch = search;
        lastSearchLimit = limit;
        lastSearchPage = page;
        
        // Return the request
        return request;
    }
    
    /// Gets the post at the given ID and returns a BCBooruPost(Can be nil)
    func getPostFromId(_ id : Int, completionHandler: @escaping (BCBooruPost?) -> ()) -> Request? {
        /// The request that will be made, and then returned
        var request : Request? = nil;
        
        // Get the post
        // Depending on which Booru API we are using...
        if(type == .moebooru) {
            // Make the get request to the Booru with the post ID...
            request = Alamofire.request(baseUrl + "/post.json?tags=id:" + String(id)).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // Return the post from the JSON we got
                    completionHandler(self.getPostFromData(json: responseJson[0], xml: nil));
                }
            }
        }
        else if(type == .danbooruLegacy) {
            // Make the get request to the Booru with the post ID...
            request = Alamofire.request(baseUrl + "/post/index.xml?page=1&limit=1&tags=id:" + String(id)).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The XML from the response string
                    let responseXml = SWXMLHash.parse(dataFromResponseJsonString);
                    
                    // If there is a first element in the posts children...
                    if(responseXml["posts"].children.count > 0) {
                        // Return the post from the XML we got
                        completionHandler(self.getPostFromData(json: nil, xml: responseXml["posts"].children[0]));
                    }
                }
            }
        }
        else if(type == .danbooru) {
            // Make the get request to the Booru with the post ID...
            request = Alamofire.request(baseUrl + "/posts.json?tags=id:" + String(id)).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // Return the post from the JSON we got
                    completionHandler(self.getPostFromData(json: responseJson[0], xml: nil));
                }
            }
        }
        else if(type == .gelbooru) {
            // Make the get request to the Booru with the post ID...
            request = Alamofire.request(baseUrl + "/index.php?page=dapi&s=post&q=index&tags=id:" + String(id)).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The XML from the response string
                    let responseXml = SWXMLHash.parse(dataFromResponseJsonString);
                    
                    // If there is a first element in the posts children...
                    if(responseXml["posts"].children.count > 0) {
                        // Return the post from the XML we got
                        completionHandler(self.getPostFromData(json: nil, xml: responseXml["posts"].children[0]));
                    }
                }
            }
        }
        
        // Return the request
        return request;
    }
    
    /// Returns a BCBooruPOst from the given data(Can be nil)
    func getPostFromData(json : JSON?, xml : XMLIndexer?) -> BCBooruPost? {
        /// The post to return
        var post : BCBooruPost? = nil;
        
        // Get the post
        // Depending on which Booru API we are using...
        if(type == .moebooru) {
            // Make post a new BCBooruPost
            post = BCBooruPost();
            
            // Set the post's info
            post?.thumbnailUrl = json!["preview_url"].stringValue;
            post?.thumbnailSize = NSSize(width: json!["actual_preview_width"].intValue, height: json!["actual_preview_height"].intValue);
            
            post?.imageUrl = json!["file_url"].stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
            post?.imageSize = NSSize(width: json!["width"].intValue, height: json!["height"].intValue);
            
            switch(json!["rating"]) {
                case "s":
                    post?.rating = .safe;
                    break;
                case "q":
                    post?.rating = .questionable;
                    break;
                case "e":
                    post?.rating = .explicit;
                    break;
                default:
                    print("BCBooruUtilities: Rating for post \(json!["id"])(\(json!["rating"])) is invalid");
                    break;
            }
            
            post?.tags = json!["tags"].stringValue.components(separatedBy: " ");
            
            // Filter out any possibly empty tags from the tags
            post?.tags = post!.tags.filter({$0 != ""});
            
            post?.id = json!["id"].intValue;
            
            post?.url = self.baseUrl + "/post/show/\(post!.id)";
        }
        else if(type == .danbooruLegacy) {
            // Make post a new BCBooruPost
            post = BCBooruPost();
            
            // Set the post's info
            post?.thumbnailUrl = self.baseUrl + xml!.element!.allAttributes["preview_url"]!.text;
            post?.thumbnailSize = NSSize(width: NSString(string: xml!.element!.allAttributes["width"]!.text).integerValue, height: NSString(string: xml!.element!.allAttributes["height"]!.text).integerValue);
            
            post?.imageUrl = self.baseUrl + xml!.element!.allAttributes["file_url"]!.text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
            post?.imageSize = NSSize(width: NSString(string: xml!.element!.allAttributes["width"]!.text).integerValue, height: NSString(string: xml!.element!.allAttributes["height"]!.text).integerValue);
            
            switch(xml!.element!.allAttributes["rating"]!.text) {
            case "s":
                post?.rating = .safe;
                break;
            case "q":
                post?.rating = .questionable;
                break;
            case "e":
                post?.rating = .explicit;
                break;
            default:
                print("BCBooruUtilities: Rating for post \(xml!.element!.allAttributes["id"]!.text)(\(xml!.element!.allAttributes["rating"]!.text)) is invalid");
                break;
            }
            
            post?.tags = xml!.element!.allAttributes["tags"]!.text.components(separatedBy: " ");
            
            // For some reason the tags attribute on Gelbooru always starts with a space, and it creates a empty tag as the first element in the tags array. Check if it exists, and if it does, remove it(And it also does the same with the last)
            if(post?.tags[0] == "") {
                post?.tags.removeFirst();
            }
            if(post?.tags[(post?.tags.count)! - 1] == "") {
                post?.tags.removeLast();
            }
            
            // Filter out any possibly empty tags from the tags
            post?.tags = post!.tags.filter({$0 != ""});
            
            post?.id = NSString(string: xml!.element!.allAttributes["id"]!.text).integerValue;
            
            post?.url = self.baseUrl + "/posts/\(post!.id)";
        }
        else if(type == .danbooru) {
            // Make post a new BCBooruPost
            post = BCBooruPost();
            
            // Set the post's info
            post?.thumbnailUrl = baseUrl + json!["preview_file_url"].stringValue;
            
            // Danbooru doesnt give you a thumbnail size
            post?.thumbnailSize = NSSize.zero;
            
            post?.imageUrl = baseUrl + json!["file_url"].stringValue.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
            post?.imageSize = NSSize(width: json!["image_width"].intValue, height: json!["image_height"].intValue);
            
            switch(json!["rating"]) {
            case "s":
                post?.rating = .safe;
                break;
            case "q":
                post?.rating = .questionable;
                break;
            case "e":
                post?.rating = .explicit;
                break;
            default:
                print("BCBooruUtilities: Rating for post \(json!["id"])(\(json!["rating"])) is invalid");
                break;
            }
            
            post?.tags = json!["tag_string_artist"].stringValue.components(separatedBy: " ");
            post?.tags.append(contentsOf: json!["tag_string_character"].stringValue.components(separatedBy: " "));
            post?.tags.append(contentsOf: json!["tag_string_copyright"].stringValue.components(separatedBy: " "));
            post?.tags.append(contentsOf: json!["tag_string_general"].stringValue.components(separatedBy: " "));
            
            // Filter out any possibly empty tags from the tags
            post?.tags = post!.tags.filter({$0 != ""});
            
            post?.id = json!["id"].intValue;
            
            post?.url = self.baseUrl + "/posts/\(post!.id)";
        }
        else if(type == .gelbooru) {
            // Make post a new BCBooruPost
            post = BCBooruPost();
            
            // Set the post's info
            post?.thumbnailUrl = xml!.element!.allAttributes["preview_url"]!.text;
            post?.thumbnailSize = NSSize(width: NSString(string: xml!.element!.allAttributes["preview_width"]!.text).integerValue, height: NSString(string: xml!.element!.allAttributes["preview_height"]!.text).integerValue);
            
            post?.imageUrl = xml!.element!.allAttributes["file_url"]!.text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
            post?.imageSize = NSSize(width: NSString(string: xml!.element!.allAttributes["width"]!.text).integerValue, height: NSString(string: xml!.element!.allAttributes["height"]!.text).integerValue);
            
            switch(xml!.element!.allAttributes["rating"]!.text) {
                case "s":
                    post?.rating = .safe;
                    break;
                case "q":
                    post?.rating = .questionable;
                    break;
                case "e":
                    post?.rating = .explicit;
                    break;
                default:
                    print("BCBooruUtilities: Rating for post \(xml!.element!.allAttributes["id"]!.text)(\(xml!.element!.allAttributes["rating"]!.text)) is invalid");
                    break;
            }
            
            post?.tags = xml!.element!.allAttributes["tags"]!.text.components(separatedBy: " ");
            
            // For some reason the tags attribute on Gelbooru always starts with a space, and it creates a empty tag as the first element in the tags array. Check if it exists, and if it does, remove it(And it also does the same with the last)
            if(post?.tags[0] == "") {
                post?.tags.removeFirst();
            }
            if(post?.tags[(post?.tags.count)! - 1] == "") {
                post?.tags.removeLast();
            }
            
            // Filter out any possibly empty tags from the tags
            post?.tags = post!.tags.filter({$0 != ""});
            
            post?.id = NSString(string: xml!.element!.allAttributes["id"]!.text).integerValue;
            
            post?.url = self.baseUrl + "/index.php?page=post&s=view&id=\(post!.id)";
        }
        
        /// The protocol of this Booru's URL
        let urlProtocol : String = self.representedBooru!.url.substring(to: self.representedBooru!.url.range(of: "//")!.lowerBound);
        
        // If the image URL doesn't have a protocol...
        if(post?.imageUrl.hasPrefix("//") ?? false) {
            // Fix the image URL to also have the protocol
            post!.imageUrl = urlProtocol + post!.imageUrl;
        }
        
        // If the thumbnail URL doesn't have a protocol...
        if(post?.thumbnailUrl.hasPrefix("//") ?? false) {
            // Fix the thumbnail URL to also have the protocol
            post!.thumbnailUrl = urlProtocol + post!.thumbnailUrl;
        }
        
        // Return the post
        return post;
    }
    
    // Init with a Booru host
    convenience init(booru : BCBooruHost) {
        self.init();
        
        // Set representedBooru
        self.representedBooru = booru;
        
        // Set the type
        self.type = booru.type;
        
        // Set the host
        self.baseUrl = booru.url;
        
        // Set the maximum rating
        self.maximumRating = booru.maximumRating;
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
    var rating : BCRating = BCRating.safe;
    
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

class BCBooruHost: NSObject, NSCoding {
    /// The display name of this Booru
    var name : String = "";
    
    /// What type of Booru this is
    var type : BCBooruType = .unchosen;
    
    /// How many posts to show per page
    var pagePostLimit : Int = 40;
    
    /// The maximum rating of post to show on this Booru
    var maximumRating : BCRating = .explicit;
    
    /// The tags the user has entered into this Booru for searching before
    var tagHistory : [String] = [];
    
    /// The IDs of all the posts that the user has downloaded from this Booru
    var downloadedPosts : [Int] = [];
    
    /// The URL to this Booru
    var url : String = "";
    
    /// The tag blacklist for this booru, filters out any posts that has any of these tags when returning search results
    var tagBlacklist : [String] = [];
    
    /// The BCBooruUtilities for this host
    var utilties : BCBooruUtilities!;
    
    /// Adds the given tag to this Booru's tag search history
    func addTagToHistory(_ tag : String) {
        // If tagHistory doesnt have the given tag...
        if(!tagHistory.contains(tag)) {
            // Add the given tag to tagHistory
            tagHistory.append(tag);
            
            // Print what tag we added to the tag history
            print("BCBooruHost(\(self.name)): Added tag \"\(tag)\" to tag history");
        }
    }
    
    /// Adds the given ID to this Booru's downloaded posts
    func addIDToDownloadHistory(_ id : Int) {
        // If downloadedPosts doesnt already have this ID...
        if(!downloadedPosts.contains(id)) {
            // Add the given ID to downloadedPosts
            downloadedPosts.append(id);
            
            // Print what ID we added to the download history
            print("BCBooruHost(\(self.name)): Added post \(id) to download history");
        }
    }
    
    /// Has this Booru downloaded the given ID?
    func hasDownloadedId(_ id : Int) -> Bool {
        // Return if downloadedPosts contains the given ID
        return downloadedPosts.contains(id);
    }
    
    /// The path to this Booru's cache folder
    var cacheFolderPath : String = "$NOTSET$";
    
    /// Creates the cache folder for this Booru(If it doesnt exist)
    func createCacheFolder() {
        // Set the cache folder path
        self.cacheFolderPath = NSHomeDirectory() + "/Library/Application Support/Booru-chan/caches/" + self.name + "/";
        
        // If the cache folder doesnt exist and cacheFolderPath is set...
        if(!FileManager.default.fileExists(atPath: cacheFolderPath) && cacheFolderPath != "$NOTSET$") {
            do {
                // Create the cache folder
                try FileManager.default.createDirectory(atPath: cacheFolderPath, withIntermediateDirectories: false, attributes: nil);
            }
            catch let error as NSError {
                // Print the error
                print("BCBooruHost(\(self.name)): Failed to create cache folder, \(error.description)");
            }
        }
    }
    
    /// Updates utilties to match the current host info
    func refreshUtilities() {
        // Update utilities
        self.utilties = BCBooruUtilities(booru: self);
    }
    
    // Init with a name, type, page post limit and URL
    convenience init(name : String, type : BCBooruType, pagePostLimit : Int, url : String, maximumRating : BCRating) {
        self.init();
        
        self.name = name;
        self.type = type;
        self.url = url;
        self.pagePostLimit = pagePostLimit;
        self.maximumRating = maximumRating;
        
        self.utilties = BCBooruUtilities(booru: self);
    }
    
    func encode(with coder: NSCoder) {
        // Encode the values
        coder.encode(self.name, forKey: "name");
        coder.encode(self.type.rawValue, forKey: "type");
        coder.encode(self.pagePostLimit, forKey: "pagePostLimit");
        coder.encode(self.url, forKey: "url");
        coder.encode(self.maximumRating.rawValue, forKey: "maximumRating");
        coder.encode(self.tagHistory, forKey: "tagHistory");
        coder.encode(self.downloadedPosts, forKey: "downloadedPosts");
        coder.encode(self.tagBlacklist, forKey: "tagBlacklist");
    }
    
    required convenience init(coder decoder: NSCoder) {
        self.init();
        
        // Decode and load the values
        if((decoder.decodeObject(forKey: "name") as? String) != nil) {
            self.name = decoder.decodeObject(forKey: "name") as! String;
        }
        
        self.type = BCBooruType(rawValue: decoder.decodeInteger(forKey: "type"))!;
        self.pagePostLimit = decoder.decodeInteger(forKey: "pagePostLimit");
        
        if((decoder.decodeObject(forKey: "url") as? String) != nil) {
            self.url = decoder.decodeObject(forKey: "url") as! String;
        }
        
        self.maximumRating = BCRating(rawValue: decoder.decodeInteger(forKey: "maximumRating"))!;
        
        if((decoder.decodeObject(forKey: "tagHistory") as? [String]) != nil) {
            self.tagHistory = decoder.decodeObject(forKey: "tagHistory") as! [String]!;
        }
        
        if((decoder.decodeObject(forKey: "downloadedPosts") as? [Int]) != nil) {
            self.downloadedPosts = decoder.decodeObject(forKey: "downloadedPosts") as! [Int]!;
        }
        
        if((decoder.decodeObject(forKey: "tagBlacklist") as? [String]) != nil) {
            self.tagBlacklist = decoder.decodeObject(forKey: "tagBlacklist") as! [String]!;
        }
        
        self.utilties = BCBooruUtilities(booru: self);
    }
}

/// The different types of Booru Booru-chan can use
enum BCBooruType: Int {
    /// Used for placeholders/variable initiation
    case unchosen
    
    /// Moebooru
    case moebooru
    
    /// Danbooru 1.x
    case danbooruLegacy
    
    /// Danbooru 2.x
    case danbooru
    
    /// Gelbooru
    case gelbooru
}

/// The different ratings a post can have
enum BCRating: Int {
    /// Safe
    case safe
    
    /// Questionable(Red face)
    case questionable
    
    /// Explicit(L-lewd...)
    case explicit
}
