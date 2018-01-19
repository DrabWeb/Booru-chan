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

    private(set) weak var representedBooru: BooruHost!

    var lastSearch = "";
    var lastSearchLimit = -1;
    var lastSearchPage = -1;

    func getAutocompleteSuggestionsFromSearch(_ search: String, limit: Int, completionHandler: @escaping ([Tag]) -> ()) -> Request? {
        print("BooruUtilities: Searching for autocomplete suggestions for \"\(search)\" on \(representedBooru.name)");

        var results: [Tag] = [];
        var request: Request? = nil;

        if representedBooru.type == .moebooru {
            // /tag.json?name=[search]&order=[date|count|name]&limit=[limit]
            let url = sanitizeUrl("\(representedBooru.url)/tag.json?name=\(search)*&order=count&limit=\(limit)");
            print("BooruUtilities: Using \(url) to search for tags");

            request = jsonRequest(url: url, completionHandler: { json in
                for (_, t) in json.enumerated() {
                    var type = TagType.general;

                    // general: 0, artist: 1, copyright: 3, character: 4
                    switch t.1["type"].intValue {
                        case 1:
                            type = .artist;
                            break;
                        case 3:
                            type = .copyright;
                            break;
                        case 4:
                            type = .character;
                            break;
                        default:
                            break;
                    }

                    results.append(Tag(name: t.1["name"].stringValue, type: type, postCount: t.1["count"].intValue));
                }

                completionHandler(results);
            });
        }
        else if representedBooru.type == .danbooru || representedBooru.type == .danbooruLegacy {
            // /tags.json?search[name_matches]=[search]&search[order]=[date|count|name]]&limit=[limit]
            // note: danbooru does not support getting all tags from a search, and has an upper limit of 1000 and a lower limit of 0
            let url = sanitizeUrl("\(representedBooru.url)/tags.json?search[name_matches]=\(search)*&search[order]=count&limit=\(limit)");
            print("BooruUtilities: Using \(url) to search for tags");

            request = jsonRequest(url: url, completionHandler: { json in
                for (_, t) in json.enumerated() {
                    var type = TagType.general;

                    // general: 0, artist: 1, copyright: 3, character: 4
                    switch t.1["category"].intValue {
                        case 1:
                            type = .artist;
                            break;
                        case 3:
                            type = .copyright;
                            break;
                        case 4:
                            type = .character;
                            break;
                        default:
                            break;
                    }

                    results.append(Tag(name: t.1["name"].stringValue, type: type, postCount: t.1["post_count"].intValue));
                }

                completionHandler(results);
            });
        }
        else if representedBooru.type == .gelbooru {
            // gelbooru does not support tag searching
            completionHandler([]);
        }

        return request;
    }

    func getPostsFromSearch(_ search: String, limit: Int, page: Int, completionHandler: @escaping ([BooruPost]) -> ()) -> Request? {
        print("BooruUtilities: Searching for \"\(search)\", limit: \(limit), page: \(page) on \(representedBooru.name)");

        var results: [BooruPost] = [];
        var request: Request? = nil;

        var ratingLimitString: String = "";
        switch representedBooru.maximumRating {
            case .safe:
                ratingLimitString = " rating:safe";
                break;
            case .questionable:
                ratingLimitString = " -rating:explicit";
                break;
            default:
                break;
        }

        func handlePost(_ post: BooruPost) {
            if !self.postIsBlacklisted(post) {
                results.append(post);
            }
        }

        //todo: get tag types for all supported boorus
        // moebooru only seems to have summary.json, a gigantic string with all the tags and their types

        if representedBooru.type == .moebooru {
            // /post.json?tags=[search]&page=[page]&limit=[limit]
            let url = sanitizeUrl("\(representedBooru.url)/post.json?tags=\(search + ratingLimitString)&page=\(page)&limit=\(limit)");
            print("BooruUtilities: Using \(url) to search");

            request = jsonRequest(url: url, completionHandler: { json in
                for (_, currentResult) in json.enumerated() {
                    handlePost(self.getPostFromData(json: currentResult.1));
                }

                completionHandler(results);
            });
        }
        else if representedBooru.type == .danbooruLegacy {
            // /post/index.xml?page=[page]&limit=[limit]&tags=[tags]
            let url = sanitizeUrl("\(representedBooru.url)/post/index.xml?page=\(page)&limit=\(limit)&tags=\(search + ratingLimitString)");
            print("BooruUtilities: Using \(url) to search");

            request = xmlRequest(url: url, completionHandler: { xml in
                for (_, currentResult) in xml["posts"].children.enumerated() {
                    handlePost(self.getPostFromData(xml: currentResult));
                }

                completionHandler(results);
            });
        }
        else if representedBooru.type == .danbooru {
            // /posts.json?tags=[tags]&page=[page]&limit=[limit]
            let url = sanitizeUrl("\(representedBooru.url)/posts.json?tags=\(search + ratingLimitString)&page=\(page)&limit=\(limit)");
            print("BooruUtilities: Using \(url) to search");

            request = jsonRequest(url: url, completionHandler: { json in
                for (_, currentResult) in json.enumerated() {
                    handlePost(self.getPostFromData(json: currentResult.1));
                }

                completionHandler(results);
            });
        }
        else if representedBooru.type == .gelbooru {
            // /index.php?page=dapi&s=post&q=index&tags=[tags]&pid=[page - 1]&limit=[limit]
            let url = sanitizeUrl("\(representedBooru.url)/index.php?page=dapi&s=post&q=index&tags=\(search + ratingLimitString)&pid=\(page - 1)&limit=\(limit)");
            print("BooruUtilities: Using \(url) to search");

            request = xmlRequest(url: url, completionHandler: { xml in
                for (_, currentResult) in xml["posts"].children.enumerated() {
                    handlePost(self.getPostFromData(xml: currentResult));
                }

                completionHandler(results);
            });
        }

        lastSearch = search;
        lastSearchLimit = limit;
        lastSearchPage = page;
        representedBooru.searchHistory.append(search);

        return request;
    }

    func getPostFromId(_ id: Int, completionHandler: @escaping (BooruPost?) -> Void) -> Request? {
        return getPostsFromSearch("id:\(id)", limit: 1, page: 1, completionHandler: { posts in
            completionHandler(posts.first);
        });
    }

    func getPostFromData(json: JSON? = nil, xml: XMLIndexer? = nil) -> BooruPost {
        let post: BooruPost = BooruPost();

        if representedBooru.type == .moebooru {
            post.id = json!["id"].intValue;
            post.url = "\(representedBooru.url)/post/show/\(post.id)";
            post.tags = tagsFrom(string: json!["tags"].stringValue);

            post.thumbnailUrl = sanitizeUrl(json!["preview_url"].stringValue);
            post.thumbnailSize = NSSize(width: json!["actual_preview_width"].intValue,
                                        height: json!["actual_preview_height"].intValue);

            post.imageUrl = sanitizeUrl(json!["file_url"].stringValue);
            post.imageSize = NSSize(width: json!["width"].intValue,
                                     height: json!["height"].intValue);

            let r = json!["rating"];
            switch r {
                case "s":
                    post.rating = .safe;
                    break;
                case "q":
                    post.rating = .questionable;
                    break;
                case "e":
                    post.rating = .explicit;
                    break;
                default:
                    print("BooruUtilities: Rating \(r) for post \(post.id) is invalid");
                    break;
            }
        }
        else if representedBooru.type == .danbooruLegacy {
            post.id = NSString(string: xml!.element!.allAttributes["id"]!.text).integerValue;
            post.url = "\(representedBooru.url)/posts/\(post.id)";
            post.tags = tagsFrom(string: xml!.element!.allAttributes["tags"]!.text);

            // danbooru legacy doesnt have thumbnail resolution in the api
            post.thumbnailUrl = sanitizeUrl("\(representedBooru.url)/\(xml?.element?.allAttributes["preview_url"]?.text ?? "")");
            post.thumbnailSize = NSSize.zero;

            post.imageUrl = sanitizeUrl("\(representedBooru.url)/\(xml?.element?.allAttributes["file_url"]?.text ?? "")");
            post.imageSize = NSSize(width: NSString(string: xml!.element!.allAttributes["width"]!.text).integerValue,
                                    height: NSString(string: xml!.element!.allAttributes["height"]!.text).integerValue);

            let r = xml!.element!.allAttributes["rating"]!.text;
            switch r {
                case "s":
                    post.rating = .safe;
                    break;
                case "q":
                    post.rating = .questionable;
                    break;
                case "e":
                    post.rating = .explicit;
                    break;
                default:
                    print("BooruUtilities: Rating \(r) for post \(post.id) is invalid");
                    break;
            }
        }
        else if representedBooru.type == .danbooru {
            post.id = json!["id"].intValue;
            post.url = "\(representedBooru.url)/posts/\(post.id)";

            func addTags(key: String, type: TagType) {
                post.tags.append(contentsOf: tagsFrom(string: json![key].stringValue, type: type));
            }

            addTags(key: "tag_string_copyright", type: .copyright);
            addTags(key: "tag_string_character", type: .character);
            addTags(key: "tag_string_artist", type: .artist);
            addTags(key: "tag_string_general", type: .general);

            // danbooru doesnt have thumbnail resolution in the api
            post.thumbnailUrl = sanitizeUrl("\(representedBooru.url)/\(json!["preview_file_url"].stringValue)");
            post.thumbnailSize = NSSize.zero;

            post.imageUrl = sanitizeUrl("\(representedBooru.url)/\(json!["file_url"].stringValue)");
            post.imageSize = NSSize(width: json!["image_width"].intValue,
                                    height: json!["image_height"].intValue);

            let r = json!["rating"];
            switch r {
                case "s":
                    post.rating = .safe;
                    break;
                case "q":
                    post.rating = .questionable;
                    break;
                case "e":
                    post.rating = .explicit;
                    break;
                default:
                    print("BooruUtilities: Rating \(r) for post \(post.id) is invalid");
                    break;
            }
        }
        else if representedBooru.type == .gelbooru {
            post.id = NSString(string: xml!.element!.allAttributes["id"]!.text).integerValue;
            post.url = "\(representedBooru.url)/index.php?page=post&s=view&id=\(post.id)";
            post.tags = tagsFrom(string: xml!.element!.allAttributes["tags"]!.text);

            post.thumbnailUrl = sanitizeUrl(xml!.element!.allAttributes["preview_url"]!.text);
            post.thumbnailSize = NSSize(width: NSString(string: xml!.element!.allAttributes["preview_width"]!.text).integerValue,
                                         height: NSString(string: xml!.element!.allAttributes["preview_height"]!.text).integerValue);

            post.imageUrl = sanitizeUrl(xml!.element!.allAttributes["file_url"]!.text);
            post.imageSize = NSSize(width: NSString(string: xml!.element!.allAttributes["width"]!.text).integerValue,
                                     height: NSString(string: xml!.element!.allAttributes["height"]!.text).integerValue);

            let r = xml!.element!.allAttributes["rating"]!.text;
            switch r {
                case "s":
                    post.rating = .safe;
                    break;
                case "q":
                    post.rating = .questionable;
                    break;
                case "e":
                    post.rating = .explicit;
                    break;
                default:
                    print("BooruUtilities: Rating \(r) for post \(post.id) is invalid");
                    break;
            }
        }

        let booruUrlProtocol = String(self.representedBooru!.url[..<self.representedBooru!.url.range(of: "//")!.lowerBound]);

        if post.imageUrl.hasPrefix("//") {
            post.imageUrl = booruUrlProtocol + post.imageUrl;
        }

        if post.thumbnailUrl.hasPrefix("//") {
            post.thumbnailUrl = booruUrlProtocol + post.thumbnailUrl;
        }

        return post;
    }

    private func jsonRequest(url: String, completionHandler: @escaping (JSON) -> Void) -> Request {
        return Alamofire.request(url).responseJSON { responseData in
            let jsonString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
            if let jsonData = jsonString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                if let json = try? JSON(data: jsonData) {
                    completionHandler(json);
                }
            }
        }
    }

    private func xmlRequest(url: String, completionHandler: @escaping (XMLIndexer) -> Void) -> Request {
        return Alamofire.request(url).responseJSON { responseData in
            let xmlString = NSString(data: responseData.data!, encoding: String.Encoding.utf8.rawValue)!;
            if let xmlData = xmlString.data(using: String.Encoding.utf8.rawValue, allowLossyConversion: false) {
                completionHandler(SWXMLHash.parse(xmlData));
            }
        }
    }

    private func sanitizeUrl(_ url: String) -> String {
        return url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!.replacingOccurrences(of: " ", with: "%20");
    }

    private func postIsBlacklisted(_ post: BooruPost) -> Bool {
        var containsTagInBlacklist = false;

        if self.representedBooru.tagBlacklist.count > 0 {
            for (_, t) in post.tags.enumerated() {
                if self.representedBooru!.tagBlacklist.contains(t) {
                    print("BooruUtilities: Blacklisted post \(post.id) from \(self.representedBooru!.name) for tag \"\(t)\"");
                    containsTagInBlacklist = true;
                    break;
                }
            }
        }

        return containsTagInBlacklist;
    }

    private func tagsFrom(string: String, type: TagType = .general) -> [Tag] {
        return string.components(separatedBy: " ").filter { !$0.isEmpty }.map { Tag(name: $0, type: type) };
    }

    convenience init(booru: BooruHost) {
        self.init();
        self.representedBooru = booru;
    }
}
