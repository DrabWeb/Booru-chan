//
//  BooruUtilities.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-14.
//

import Alamofire
import SwiftyJSON
import SWXMLHash

class BooruUtilities {
    /// The BooruHost this booru utilities represents
    weak var representedBooru : BooruHost? = nil;

    /// The type of Booru to use for this Booru Utilities
    var type : BooruType = .unchosen;

    /// The base URL of this Booru(Without a trailing slash)
    var baseUrl : String = "";

    /// The last search string
    var lastSearch : String = "";

    /// The limit of the last search
    var lastSearchLimit : Int = -1;

    /// The page of the last search
    var lastSearchPage = -1;

    /// The maximum rating of post to show when searching
    var maximumRating : Rating = .explicit;

    /// Returns an array of Strings containing all the tags that matched the passed query(You can do things like *query, query* and *query*)
    func getTagsMatchingSearch(_ search : String, completionHandler: @escaping ([String]) -> ()) -> Request? {
        // Print what we are searching for
        print("BooruUtilities: Searching for tags matching \"\(search)\" on \"\(self.baseUrl)\"");

        /// The request that will be made, and then returned
        var request : Request? = nil;

        /// The tag search results to pass to the completion handler
        var results : [String] = [];

        // Get the tags with the passed query
        // Depending on which Booru API we are using...
        if(type == .moebooru) {
            // baseUrl/tag.json?name=search
            // Print what URL we are using
            print("BooruUtilities: Using URL \((baseUrl + "/tag.json?name=" + search + "&limit=0")) to search for tags");

            // Make the request to get the tags
            request = Alamofire.request((baseUrl + "/tag.json?name=" + search + "&limit=0").replacingOccurrences(of: " ", with: "%20")).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;

                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = try! JSON(data: dataFromResponseJsonString);

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
            print("BooruUtilities: Using URL \((baseUrl + "/tags.json?search[name_matches]=" + search + "&limit=1000")) to search for tags");

            // Make the request to get the tags(It seems Danbooru has a tag request limit of 1000(Using 0 gives you none), so I use 1000 here)
            request = Alamofire.request((baseUrl + "/tags.json?search[name_matches]=" + search + "&limit=1000").replacingOccurrences(of: " ", with: "%20")).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;

                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = try! JSON(data: dataFromResponseJsonString);

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
    func getPostsFromSearch(_ search : String, limit : Int, page : Int, completionHandler: @escaping ([BooruPost]) -> ()) -> Request? {
        // Print what we are searching for
        print("BooruUtilities: Searching for \"\(search)\"(Limit \(limit), page \(page)) on \"\(self.baseUrl)\"");

        /// The search results to pass to the completion handler
        var results : [BooruPost] = [];

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
            print("BooruUtilities: Using URL \"\(requestUrl)\" to search");

            // Make the get request to the Booru with the search string and rating limit...
            request = Alamofire.request(requestUrl).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;

                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = try! JSON(data: dataFromResponseJsonString);

                    // For every search result...
                    for(_, currentResult) in responseJson.enumerated() {
                        /// The BCBooruPost from currentResult
                        let post : BooruPost = self.getPostFromData(json: currentResult.1, xml: nil)!;

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
                                    print("BooruUtilities: Blacklisted post \(post.id) from \(self.representedBooru!.name) for tag \"\(currentTag)\"");

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
            print("BooruUtilities: Using URL \"\(requestUrl)\" to search");

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
                        let post : BooruPost = self.getPostFromData(json: nil, xml: currentResult)!;

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
                                    print("BooruUtilities: Blacklisted post \(post.id) from \(self.representedBooru!.name) for tag \"\(currentTag)\"");

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
            print("BooruUtilities: Using URL \"\(requestUrl)\" to search");

            // Make the get request to the Booru with the search string and rating limit...
            request = Alamofire.request(requestUrl).responseJSON { (responseData) -> Void in
                /// The string of JSON that will be returned when the GET request finishes
                let responseJsonString : NSString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;

                // If the the response data isnt nil...
                if let dataFromResponseJsonString = responseJsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                    /// The JSON from the response string
                    let responseJson = try! JSON(data: dataFromResponseJsonString);

                    // For every search result...
                    for(_, currentResult) in responseJson.enumerated() {
                        /// The BCBooruPost from currentResult
                        let post : BooruPost = self.getPostFromData(json: currentResult.1, xml: nil)!;

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
                                    print("BooruUtilities: Blacklisted post \(post.id) from \(self.representedBooru!.name) for tag \"\(currentTag)\"");

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
            print("BooruUtilities: Using URL \"\(requestUrl)\" to search");

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
                        let post : BooruPost = self.getPostFromData(json: nil, xml: currentResult)!;

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
                                    print("BooruUtilities: Blacklisted post \(post.id) from \(self.representedBooru!.name) for tag \"\(currentTag)\"");

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
    func getPostFromId(_ id : Int, completionHandler: @escaping (BooruPost?) -> ()) -> Request? {
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
                    let responseJson = try! JSON(data: dataFromResponseJsonString);

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
                    let responseJson = try! JSON(data: dataFromResponseJsonString);

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
    func getPostFromData(json : JSON?, xml : XMLIndexer?) -> BooruPost? {
        /// The post to return
        var post : BooruPost? = nil;

        // Get the post
        // Depending on which Booru API we are using...
        if(type == .moebooru) {
            // Make post a new BCBooruPost
            post = BooruPost();

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
                print("BooruUtilities: Rating for post \(json!["id"])(\(json!["rating"])) is invalid");
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
            post = BooruPost();

            // Set the post's info
            post?.thumbnailUrl = self.baseUrl + (xml?.element?.allAttributes["preview_url"]?.text ?? "");
            post?.thumbnailSize = NSSize(width: NSString(string: xml!.element!.allAttributes["width"]!.text).integerValue, height: NSString(string: xml!.element!.allAttributes["height"]!.text).integerValue);

            post?.imageUrl = self.baseUrl + (xml?.element?.allAttributes["file_url"]?.text ?? "").addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
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
                print("BooruUtilities: Rating for post \(xml!.element!.allAttributes["id"]!.text)(\(xml!.element!.allAttributes["rating"]!.text)) is invalid");
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
            post = BooruPost();

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
                print("BooruUtilities: Rating for post \(json!["id"])(\(json!["rating"])) is invalid");
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
            post = BooruPost();

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
                print("BooruUtilities: Rating for post \(xml!.element!.allAttributes["id"]!.text)(\(xml!.element!.allAttributes["rating"]!.text)) is invalid");
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
        let urlProtocol : String = String(self.representedBooru!.url[..<self.representedBooru!.url.range(of: "//")!.lowerBound]);

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
    convenience init(booru : BooruHost) {
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
