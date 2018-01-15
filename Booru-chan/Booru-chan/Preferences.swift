//
//  Preferences.swift
//  Booru-chan
//
//  Created by Ushio on 2016-04-25.
//

import Cocoa

class Preferences: NSObject, NSCoding {

    var imageFilenameFormat: String = "%md5%";
    var theme: Theme = .dark;
    var indicateDownloadedPosts: Bool = false;
    var notifyWhenDownloadsFinished: Bool = true;

    var booruHosts: [BooruHost] = [
        BooruHost(name: "Yande.re", type: .moebooru, pagePostLimit: 40, url: "http://yande.re/", maximumRating: .explicit),
        BooruHost(name: "Danbooru", type: .danbooru, pagePostLimit: 40, url: "http://danbooru.donmai.us/", maximumRating: .explicit),
        BooruHost(name: "Konachan", type: .moebooru, pagePostLimit: 40, url: "http://konachan.net/", maximumRating: .explicit),
        BooruHost(name: "Gelbooru", type: .gelbooru, pagePostLimit: 40, url: "https://gelbooru.com/", maximumRating: .explicit)
    ];

    //todo: save as keys/values instead of archived objects
    func encode(with coder: NSCoder) {
        coder.encode(booruHosts, forKey: "booruHosts");
        coder.encode(imageFilenameFormat, forKey: "imageSaveFormat");
        coder.encode(theme.rawValue, forKey: "theme");
        coder.encode(indicateDownloadedPosts, forKey: "indicateDownloadedPosts");
        coder.encode(notifyWhenDownloadsFinished, forKey: "notifyWhenDownloadsFinished");
    }
    
    required convenience init(coder decoder: NSCoder) {
        self.init();

        if (decoder.decodeObject(forKey: "booruHosts") as? [BooruHost]) != nil {
            self.booruHosts = decoder.decodeObject(forKey: "booruHosts") as! [BooruHost];
        }
        
        if (decoder.decodeObject(forKey: "imageSaveFormat") as? String) != nil {
            self.imageFilenameFormat = decoder.decodeObject(forKey: "imageSaveFormat") as! String;
        }
        
        self.theme = Theme(rawValue: decoder.decodeInteger(forKey: "theme"))!;
        self.indicateDownloadedPosts = decoder.decodeBool(forKey: "indicateDownloadedPosts");
        self.notifyWhenDownloadsFinished = decoder.decodeBool(forKey: "notifyWhenDownloadsFinished");
    }
}
