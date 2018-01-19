//
//  BooruHost.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-14.
//

import Foundation

class BooruHost: NSObject, NSCoding {

    var utilties: BooruUtilities!

    var name: String = "";
    var url: String = "";
    var type: BooruType = .none;
    var pagePostLimit: Int = 40;
    var maximumRating: Rating = .explicit;
    var searchHistory: [String] = [];
    var tagHistory: [Tag] = [];
    var tagBlacklist: [Tag] = [];

    //todo: reimplement download history, the old way was gross

    convenience init(name: String,
                     type: BooruType,
                     pagePostLimit: Int,
                     url: String,
                     maximumRating: Rating) {
        self.init();

        self.name = name;
        self.type = type;
        self.url = url;
        self.pagePostLimit = pagePostLimit;
        self.maximumRating = maximumRating;

        refreshUtilities();
    }

    func refreshUtilities() {
        self.utilties = BooruUtilities(booru: self);
    }

    //todo: store as key and value instead of encoded objects
    func encode(with coder: NSCoder) {
        coder.encode(self.name, forKey: "name");
        coder.encode(self.type.rawValue, forKey: "type");
        coder.encode(self.pagePostLimit, forKey: "pagePostLimit");
        coder.encode(self.url, forKey: "url");
        coder.encode(self.maximumRating.rawValue, forKey: "maximumRating");
        coder.encode(self.searchHistory, forKey: "searchHistory");
        coder.encode(self.tagHistory, forKey: "tagHistory");
        coder.encode(self.tagBlacklist, forKey: "tagBlacklist");
    }

    required convenience init(coder decoder: NSCoder) {
        self.init();

        if (decoder.decodeObject(forKey: "name") as? String) != nil {
            self.name = decoder.decodeObject(forKey: "name") as! String;
        }

        self.type = BooruType(rawValue: decoder.decodeInteger(forKey: "type"))!;
        self.pagePostLimit = decoder.decodeInteger(forKey: "pagePostLimit");

        if (decoder.decodeObject(forKey: "url") as? String) != nil {
            self.url = decoder.decodeObject(forKey: "url") as! String;
        }

        self.maximumRating = Rating(rawValue: decoder.decodeInteger(forKey: "maximumRating"))!;

        if (decoder.decodeObject(forKey: "searchHistory") as? [String]) != nil {
            self.searchHistory = decoder.decodeObject(forKey: "searchHistory") as! [String]!;
        }

        if (decoder.decodeObject(forKey: "tagHistory") as? [Tag]) != nil {
            self.tagHistory = decoder.decodeObject(forKey: "tagHistory") as! [Tag]!;
        }

        if (decoder.decodeObject(forKey: "tagBlacklist") as? [Tag]) != nil {
            self.tagBlacklist = decoder.decodeObject(forKey: "tagBlacklist") as! [Tag]!;
        }

        refreshUtilities();
    }
}
