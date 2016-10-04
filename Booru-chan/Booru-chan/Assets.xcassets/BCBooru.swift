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
    /// The type of Booru to use for this Booru Utilities
    var type : BCBooruType = .Unchosen;
    
    /// The base URL of this Booru(Without a trailing slash)
    var baseUrl : String = "";
    
    /// The last search string
    var lastSearch : String = "";
    
    /// The limit of the last search
    var lastSearchLimit : Int = -1;
    
    /// The page of the last search
    var lastSearchPage = -1;
    
    /// The maximum rating of post to show when searching
    var maximumRating : BCRating = .Explicit;
    
    /// Returns an array of Strings containing all the tags that matched the passed query(You can do things like *query, query* and *query*)
    func getTagsMatchingSearch(search : String, completionHandler: ([String]) -> ()) -> Request? {
        // Print what we are searching for
        print("BCBooruUtilities: Searching for tags matching \"\(search)\" on \"\(self.baseUrl)\"");
        
        /// The request that will be made, and then returned
        var request : Request? = nil;
        
        /// The tag search results to pass to the completion handler
        var results : [String] = [];
        
        // Get the tags with the passed query
        // Depending on which Booru API we are using...
        if(type == .Moebooru) {
            // baseUrl/tag.json?name=search
            // Print what URL we are using
            print("BCBooruUtilities: Using URL \((baseUrl + "/tag.json?name=" + search + "&limit=0")) to search for tags");
            
            // Make the request to get the tags
            request = Alamofire.request(.GET, (baseUrl + "/tag.json?name=" + search + "&limit=0").stringByReplacingOccurrencesOfString(" ", withString: "%20"), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // For evert tag in responseJson...
                    for(_, currentTag) in responseJson.enumerate() {
                        // Add the current tag's name to the results
                        results.append(currentTag.1["name"].stringValue);
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        else if(type == .Danbooru || type == .DanbooruLegacy) {
            /// baseUrl/tags.json?search[name_matches]=search
            // Print what URL we are using
            print("BCBooruUtilities: Using URL \((baseUrl + "/tags.json?search[name_matches]=" + search + "&limit=1000")) to search for tags");
            
            // Make the request to get the tags(It seems Danbooru has a tag request limit of 1000(Using 0 gives you none), so I use 1000 here)
            request = Alamofire.request(.GET, (baseUrl + "/tags.json?search[name_matches]=" + search + "&limit=1000").stringByReplacingOccurrencesOfString(" ", withString: "%20"), encoding: .JSON).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: NSUTF8StringEncoding)!;
                
                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = JSON(data: dataFromResponseJsonString);
                    
                    // For evert tag in responseJson...
                    for(_, currentTag) in responseJson.enumerate() {
                        // Add the current tag's name to the results
                        results.append(currentTag.1["name"].stringValue);
                    }
                    
                    // Call the completion handler with the results
                    completionHandler(results);
                }
            }
        }
        else if(type == .Gelbooru) {
            // There is no proper API for getting tags with the format "*search", "search*" or "*search*"(Or at least froom what I can find), so do nothing
        }
        
        // Return the request
        return request;
    }
    
    /// Searches for the given string and returns the results as and array of BCBooruPosts
    func getPostsFromSearch(search : String, limit : Int, page : Int, completionHandler: ([BCBooruPost]) -> ()) -> Request? {
        // Print what we are searching for
        print("BCBooruUtilities: Searching for \"\(search)\"(Limit \(limit), page \(page)) on \"\(self.baseUrl)\"");
        
        /// The search results to pass to the completion handler
        var results : [BCBooruPost] = [];
        
        /// The request that will be made, and then returned
        var request : Request? = nil;
        
        /// The string to append to the search query to set the maximum rating of posts to show
        var ratingLimitString : String = "";
        
        // If the maximum rating isnt Explicit...
        if(maximumRating != .Explicit) {
            // If the maximum rating is Safe...
            if(maximumRating == .Safe) {
                // Set rating limit string to " rating:safe"
                ratingLimitString = " rating:safe";
            }
            // If the maximum rating is Questionable...
            else if(maximumRating == .Questionable) {
                // Set rating limit string to " -rating:explicit"
                ratingLimitString = " -rating:explicit";
            }
        }
        
        // Perform the search and get the results
        // Depending on which Booru API we are using...
        if(type == .Moebooru) {
            /// The URL to make the search request to
            var requestUrl : String = (baseUrl + "/post.json?tags=" + search + ratingLimitString + "&page=" + String(page) + "&limit=" + String(limit));
            
            // Encode special characters in the request URL
            requestUrl = requestUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!;
            
            // Print what URL we are querying
            print("BCBooruUtilities: Using URL \"\(requestUrl)\" to search");
            
            // Make the get request to the Booru with the search string and rating limit...
            request = Alamofire.request(.GET, requestUrl, encoding: .JSON).responseJSON { (responseData) -> Void in
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
            /// The URL to make the search request to
            var requestUrl : String = (baseUrl + "/post/index.json?tags=" + search + ratingLimitString + "&page=" + String(page) + "&limit=" + String(limit));
            
            // Encode special characters in the request URL
            requestUrl = requestUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!;
            
            // Print what URL we are querying
            print("BCBooruUtilities: Using URL \"\(requestUrl)\" to search");
            
            // Make the get request to the Booru with the search string and rating limit...
            request = Alamofire.request(.GET, requestUrl, encoding: .JSON).responseJSON { (responseData) -> Void in
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
            /// The URL to make the search request to
            var requestUrl : String = (baseUrl + "/posts.json?tags=" + search + ratingLimitString + "&page=" + String(page) + "&limit=" + String(limit));
            
            // Encode special characters in the request URL
            requestUrl = requestUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!;
            
            // Print what URL we are querying
            print("BCBooruUtilities: Using URL \"\(requestUrl)\" to search");
            
            // Make the get request to the Booru with the search string and rating limit...
            request = Alamofire.request(.GET, requestUrl, encoding: .JSON).responseJSON { (responseData) -> Void in
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
            /// The URL to make the search request to
            var requestUrl : String = (baseUrl + "/index.php?page=dapi&s=post&q=index&tags=" + search + ratingLimitString + ratingLimitString + "&pid=" + String(page - 1) + "&limit=" + String(limit));
            
            // Encode special characters in the request URL
            requestUrl = requestUrl.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!;
            
            // Print what URL we are querying
            print("BCBooruUtilities: Using URL \"\(requestUrl)\" to search");
            
            // Make the get request to the Booru with the search string and rating limit...
            request = Alamofire.request(.GET, requestUrl, encoding: .JSON).responseJSON { (responseData) -> Void in
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
        
        // Set the last search string, page and limit
        lastSearch = search;
        lastSearchLimit = limit;
        lastSearchPage = page;
        
        // Return the request
        return request;
    }
    
    /// Gets the post at the given ID and returns a BCBooruPost(Can be nil)
    func getPostFromId(id : Int, completionHandler: (BCBooruPost?) -> ()) -> Request? {
        /// The request that will be made, and then returned
        var request : Request? = nil;
        
        // Get the post
        // Depending on which Booru API we are using...
        if(type == .Moebooru) {
            // Make the get request to the Booru with the post ID...
            request = Alamofire.request(.GET, baseUrl + "/post.json?tags=id:" + String(id), encoding: .JSON).responseJSON { (responseData) -> Void in
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
            request = Alamofire.request(.GET, baseUrl + "/post/index.json?tags=id:" + String(id), encoding: .JSON).responseJSON { (responseData) -> Void in
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
            request = Alamofire.request(.GET, baseUrl + "/posts.json?tags=id:" + String(id), encoding: .JSON).responseJSON { (responseData) -> Void in
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
            request = Alamofire.request(.GET, baseUrl + "/index.php?page=dapi&s=post&q=index&tags=id:" + String(id), encoding: .JSON).responseJSON { (responseData) -> Void in
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
        
        // Return the request
        return request;
    }
    
    /// Returns a BCBooruPOst from the given data(Can be nil)
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
            
            post?.imageUrl = json!["file_url"].stringValue;
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
                    print("BCBooruUtilities: Rating for post \(json!["id"])(\(json!["rating"])) is invalid");
                    break;
            }
            
            post?.tags = json!["tags"].stringValue.componentsSeparatedByString(" ");
            
            // Filter out any possibly empty tags from the tags
            post?.tags = post!.tags.filter({$0 != ""});
            
            post?.id = json!["id"].intValue;
            
            post?.url = self.baseUrl + "/post/show/\(post!.id)";
        }
        else if(type == .DanbooruLegacy) {
            // Make post a new BCBooruPost
            post = BCBooruPost();
            
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
                    print("BCBooruUtilities: Rating for post \(json!["id"])(\(json!["rating"])) is invalid");
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
            
            // Filter out any possibly empty tags from the tags
            post?.tags = post!.tags.filter({$0 != ""});
            
            post?.id = json!["id"].intValue;
            
            post?.url = self.baseUrl + "/posts/\(post!.id)";
        }
        else if(type == .Danbooru) {
            // Make post a new BCBooruPost
            post = BCBooruPost();
            
            // Set the post's info
            post?.thumbnailUrl = baseUrl + json!["preview_file_url"].stringValue;
            
            // Danbooru doesnt give you a thumbnail size
            post?.thumbnailSize = NSSize.zero;
            
            post?.imageUrl = baseUrl + json!["file_url"].stringValue;
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
                print("BCBooruUtilities: Rating for post \(json!["id"])(\(json!["rating"])) is invalid");
                break;
            }
            
            post?.tags = json!["tag_string_artist"].stringValue.componentsSeparatedByString(" ");
            post?.tags.appendContentsOf(json!["tag_string_character"].stringValue.componentsSeparatedByString(" "));
            post?.tags.appendContentsOf(json!["tag_string_copyright"].stringValue.componentsSeparatedByString(" "));
            post?.tags.appendContentsOf(json!["tag_string_general"].stringValue.componentsSeparatedByString(" "));
            
            // Filter out any possibly empty tags from the tags
            post?.tags = post!.tags.filter({$0 != ""});
            
            post?.id = json!["id"].intValue;
            
            post?.url = self.baseUrl + "/posts/\(post!.id)";
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
                    print("BCBooruUtilities: Rating for post \(xml!.element!.attributes["id"]!)(\(xml!.element!.attributes["rating"]!)) is invalid");
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
            
            // Filter out any possibly empty tags from the tags
            post?.tags = post!.tags.filter({$0 != ""});
            
            post?.id = NSString(string: xml!.element!.attributes["id"]!).integerValue;
            
            post?.url = self.baseUrl + "/index.php?page=post&s=view&id=\(post!.id)";
        }
        
        // Return the post
        return post;
    }
    
    // Init with a Booru host
    convenience init(booru : BCBooruHost) {
        self.init();
        
        // Set the type
        self.type = booru.type;
        
        // Set the host
        if(booru.url.substringFromIndex(booru.url.endIndex.predecessor()) == "/") {
            self.baseUrl = booru.url.substringToIndex(booru.url.endIndex.predecessor());
        }
        else {
            self.baseUrl = booru.url;
        }
        
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
    var rating : BCRating = BCRating.Safe;
    
    /// The ID of this post
    var id : Int = -1;
    
    /// The URL to this post on it's respective Booru
    var url : String = "";
}

class BCBooruHost: NSObject, NSCoding {
    /// The display name of this Booru
    var name : String = "";
    
    /// What type of Booru this is
    var type : BCBooruType = .Unchosen;
    
    /// How many posts to show per page
    var pagePostLimit : Int = 40;
    
    /// The maximum rating of post to show on this Booru
    var maximumRating : BCRating = .Explicit;
    
    /// The tags the user has entered into this Booru for searching before
    var tagHistory : [String] = [];
    
    /// The IDs of all the posts that the user has downloaded from this Booru
    var downloadedPosts : [Int] = [];
    
    /// The URL to this Booru
    var url : String = "";
    
    /// The BCBooruUtilities for this host
    var utilties : BCBooruUtilities = BCBooruUtilities();
    
    /// Adds the given tag to this Booru's tag search history
    func addTagToHistory(tag : String) {
        // If tagHistory doesnt have the given tag...
        if(!tagHistory.contains(tag)) {
            // Add the given tag to tagHistory
            tagHistory.append(tag);
            
            // Print what tag we added to the tag history
            print("BCBooruHost(\(self.name)): Added tag \"\(tag)\" to tag history");
        }
    }
    
    /// Adds the given ID to this Booru's downloaded posts
    func addIDToDownloadHistory(id : Int) {
        // If downloadedPosts doesnt already have this ID...
        if(!downloadedPosts.contains(id)) {
            // Add the given ID to downloadedPosts
            downloadedPosts.append(id);
            
            // Print what ID we added to the download history
            print("BCBooruHost(\(self.name)): Added post \(id) to download history");
        }
    }
    
    /// Has this Booru downloaded the given ID?
    func hasDownloadedId(id : Int) -> Bool {
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
        if(!NSFileManager.defaultManager().fileExistsAtPath(cacheFolderPath) && cacheFolderPath != "$NOTSET$") {
            do {
                // Create the cache folder
                try NSFileManager.defaultManager().createDirectoryAtPath(cacheFolderPath, withIntermediateDirectories: false, attributes: nil);
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
    
    func encodeWithCoder(coder: NSCoder) {
        // Encode the values
        coder.encodeObject(self.name, forKey: "name");
        coder.encodeObject(self.type.rawValue, forKey: "type");
        coder.encodeObject(self.pagePostLimit, forKey: "pagePostLimit");
        coder.encodeObject(self.url, forKey: "url");
        coder.encodeObject(self.maximumRating.rawValue, forKey: "maximumRating");
        coder.encodeObject(self.tagHistory, forKey: "tagHistory");
        coder.encodeObject(self.downloadedPosts, forKey: "downloadedPosts");
    }
    
    required convenience init(coder decoder: NSCoder) {
        self.init();
        
        // Decode and load the values
        if((decoder.decodeObjectForKey("name") as? String) != nil) {
            self.name = decoder.decodeObjectForKey("name") as! String;
        }
        
        if((decoder.decodeObjectForKey("type") as? Int) != nil) {
            self.type = BCBooruType(rawValue: decoder.decodeObjectForKey("type") as! Int)!;
        }
        
        if((decoder.decodeObjectForKey("pagePostLimit") as? Int) != nil) {
            self.pagePostLimit = decoder.decodeObjectForKey("pagePostLimit") as! Int;
        }
        
        if((decoder.decodeObjectForKey("url") as? String) != nil) {
            self.url = decoder.decodeObjectForKey("url") as! String;
        }
        
        if((decoder.decodeObjectForKey("maximumRating") as? Int) != nil) {
            self.maximumRating = BCRating(rawValue: decoder.decodeObjectForKey("maximumRating") as! Int)!;
        }
        
        if((decoder.decodeObjectForKey("tagHistory") as? [String]) != nil) {
            self.tagHistory = decoder.decodeObjectForKey("tagHistory") as! [String]!;
        }
        
        if((decoder.decodeObjectForKey("downloadedPosts") as? [Int]) != nil) {
            self.downloadedPosts = decoder.decodeObjectForKey("downloadedPosts") as! [Int]!;
        }
        
        self.utilties = BCBooruUtilities(booru: self);
    }
}

/// The different types of Booru Booru-chan can use
enum BCBooruType: Int {
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
enum BCRating: Int {
    /// Safe
    case Safe
    
    /// Questionable(Red face)
    case Questionable
    
    /// Explicit(L-lewd...)
    case Explicit
}