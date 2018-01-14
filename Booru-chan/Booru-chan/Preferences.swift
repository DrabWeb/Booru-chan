//
//  Preferences.swift
//  Booru-chan
//
//  Created by Ushio on 2016-04-25.
//

import Cocoa

class Preferences: NSObject, NSCoding {
    /// The Booru hosts the user has added
    var booruHosts : [BooruHost] = [
        BooruHost(name: "Yande.re", type: .moebooru, pagePostLimit: 40, url: "http://yande.re/", maximumRating: .explicit),
        BooruHost(name: "Danbooru", type: .danbooru, pagePostLimit: 40, url: "http://danbooru.donmai.us/", maximumRating: .explicit),
        BooruHost(name: "Konachan", type: .moebooru, pagePostLimit: 40, url: "http://konachan.net/", maximumRating: .explicit),
        BooruHost(name: "Gelbooru", type: .gelbooru, pagePostLimit: 40, url: "https://gelbooru.com/", maximumRating: .explicit)
    ];
    
    /// The format for naming saved images
    var imageSaveFormat : String = "%md5%";
    
    /// The theme for booru browsers
    var theme : Theme = .dark;
    
    /// The alpha value of a post that has already been downloaded
    var downloadedPostAlphaValue : CGFloat = 0.5;
    
    /// Should already downloaded posts be marked?
    var indicateDownloadedPosts : Bool = false;
    
    /// Should a notification show when a download finishes?
    var notifyWhenDownloadsFinished : Bool = true;
    
    func encode(with coder: NSCoder) {
        // Encode the preferences
        coder.encode(booruHosts, forKey: "booruHosts");
        coder.encode(imageSaveFormat, forKey: "imageSaveFormat");
        coder.encode(theme.rawValue, forKey: "theme");
        coder.encode(indicateDownloadedPosts, forKey: "indicateDownloadedPosts");
        coder.encode(notifyWhenDownloadsFinished, forKey: "notifyWhenDownloadsFinished");
    }
    
    required convenience init(coder decoder: NSCoder) {
        self.init();
        
        // Decode and load the preferences
        if((decoder.decodeObject(forKey: "booruHosts") as? [BooruHost]) != nil) {
            self.booruHosts = decoder.decodeObject(forKey: "booruHosts") as! [BooruHost];
        }
        
        if((decoder.decodeObject(forKey: "imageSaveFormat") as? String) != nil) {
            self.imageSaveFormat = decoder.decodeObject(forKey: "imageSaveFormat") as! String;
        }
        
        self.theme = Theme(rawValue: decoder.decodeInteger(forKey: "theme"))!;
        self.indicateDownloadedPosts = decoder.decodeBool(forKey: "indicateDownloadedPosts");
        self.notifyWhenDownloadsFinished = decoder.decodeBool(forKey: "notifyWhenDownloadsFinished");
    }
}
