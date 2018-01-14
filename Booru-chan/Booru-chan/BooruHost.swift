//
//  BooruHost.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-14.
//

import Foundation

class BooruHost: NSObject, NSCoding {
    /// The display name of this Booru
    var name : String = "";

    /// What type of Booru this is
    var type : BooruType = .unchosen;

    /// How many posts to show per page
    var pagePostLimit : Int = 40;

    /// The maximum rating of post to show on this Booru
    var maximumRating : Rating = .explicit;

    /// The tags the user has entered into this Booru for searching before
    var tagHistory : [String] = [];

    /// The IDs of all the posts that the user has downloaded from this Booru
    var downloadedPosts : [Int] = [];

    /// The URL to this Booru
    var url : String = "";

    /// The tag blacklist for this booru, filters out any posts that has any of these tags when returning search results
    var tagBlacklist : [String] = [];

    /// The BooruUtilities for this host
    var utilties : BooruUtilities!;

    /// Adds the given tag to this Booru's tag search history
    func addTagToHistory(_ tag : String) {
        // If tagHistory doesnt have the given tag and it isn't blank...
        if(!tagHistory.contains(tag) && tag != "") {
            // Add the given tag to tagHistory
            tagHistory.append(tag);

            // Print what tag we added to the tag history
            print("BooruHost(\(self.name)): Added tag \"\(tag)\" to tag history");
        }
    }

    /// Adds the given ID to this Booru's downloaded posts
    func addIDToDownloadHistory(_ id : Int) {
        // If downloadedPosts doesnt already have this ID...
        if(!downloadedPosts.contains(id)) {
            // Add the given ID to downloadedPosts
            downloadedPosts.append(id);

            // Print what ID we added to the download history
            print("BooruHost(\(self.name)): Added post \(id) to download history");
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
                print("BooruHost(\(self.name)): Failed to create cache folder, \(error.description)");
            }
        }
    }

    /// Updates utilties to match the current host info
    func refreshUtilities() {
        // Update utilities
        self.utilties = BooruUtilities(booru: self);
    }

    // Init with a name, type, page post limit and URL
    convenience init(name : String, type : BooruType, pagePostLimit : Int, url : String, maximumRating : Rating) {
        self.init();

        self.name = name;
        self.type = type;
        self.url = url;
        self.pagePostLimit = pagePostLimit;
        self.maximumRating = maximumRating;

        self.utilties = BooruUtilities(booru: self);
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

        self.type = BooruType(rawValue: decoder.decodeInteger(forKey: "type"))!;
        self.pagePostLimit = decoder.decodeInteger(forKey: "pagePostLimit");

        if((decoder.decodeObject(forKey: "url") as? String) != nil) {
            self.url = decoder.decodeObject(forKey: "url") as! String;
        }

        self.maximumRating = Rating(rawValue: decoder.decodeInteger(forKey: "maximumRating"))!;

        if((decoder.decodeObject(forKey: "tagHistory") as? [String]) != nil) {
            self.tagHistory = decoder.decodeObject(forKey: "tagHistory") as! [String]!;
        }

        if((decoder.decodeObject(forKey: "downloadedPosts") as? [Int]) != nil) {
            self.downloadedPosts = decoder.decodeObject(forKey: "downloadedPosts") as! [Int]!;
        }

        if((decoder.decodeObject(forKey: "tagBlacklist") as? [String]) != nil) {
            self.tagBlacklist = decoder.decodeObject(forKey: "tagBlacklist") as! [String]!;
        }

        self.utilties = BooruUtilities(booru: self);
    }
}
