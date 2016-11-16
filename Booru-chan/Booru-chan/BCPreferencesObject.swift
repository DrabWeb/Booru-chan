//
//  BCPreferencesObject.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-25.
//

import Cocoa

class BCPreferencesObject: NSObject, NSCoding {
    /// The Booru hosts the user has added
    // REMINDER: Set this back to init as [] when you can set your Boorus in preferences
    var booruHosts : [BCBooruHost] = [
        BCBooruHost(name: "Yande.re", type: .moebooru, pagePostLimit: 40, url: "http://yande.re/", maximumRating: .explicit),
        BCBooruHost(name: "Danbooru", type: .danbooru, pagePostLimit: 40, url: "http://danbooru.donmai.us/", maximumRating: .explicit),
        BCBooruHost(name: "Konachan", type: .moebooru, pagePostLimit: 40, url: "http://konachan.net/", maximumRating: .explicit),
        BCBooruHost(name: "Gelbooru", type: .gelbooru, pagePostLimit: 40, url: "http://gelbooru.com/", maximumRating: .explicit)
    ];
    
    /// The format for naming saved images
    var imageSaveFormat : String = "%id%(%booru%) - %tags%";
    
    /// The alpha value of a post that has already been downloaded
    var downloadedPostAlphaValue : CGFloat = 0.5;
    
    /// Should already downloaded posts be marked?
    var indicateDownloadedPosts : Bool = true;
    
    /// Should a notification show when a download finishes?
    var notifyWhenDownloadsFinished : Bool = true;
    
    func encode(with coder: NSCoder) {
        // Encode the preferences
        coder.encode(booruHosts, forKey: "booruHosts");
        coder.encode(imageSaveFormat, forKey: "imageSaveFormat");
        coder.encode(indicateDownloadedPosts, forKey: "indicateDownloadedPosts");
        coder.encode(notifyWhenDownloadsFinished, forKey: "notifyWhenDownloadsFinished");
    }
    
    required convenience init(coder decoder: NSCoder) {
        self.init();
        
        // Decode and load the preferences
        if((decoder.decodeObject(forKey: "booruHosts") as? [BCBooruHost]) != nil) {
            self.booruHosts = decoder.decodeObject(forKey: "booruHosts") as! [BCBooruHost];
        }
        
        if((decoder.decodeObject(forKey: "imageSaveFormat") as? String) != nil) {
            self.imageSaveFormat = decoder.decodeObject(forKey: "imageSaveFormat") as! String;
        }
        
        if((decoder.decodeObject(forKey: "indicateDownloadedPosts") as? Bool) != nil) {
            self.indicateDownloadedPosts = decoder.decodeObject(forKey: "indicateDownloadedPosts") as! Bool;
        }
        
        if((decoder.decodeObject(forKey: "notifyWhenDownloadsFinished") as? Bool) != nil) {
            self.notifyWhenDownloadsFinished = decoder.decodeObject(forKey: "notifyWhenDownloadsFinished") as! Bool;
        }
    }
}
