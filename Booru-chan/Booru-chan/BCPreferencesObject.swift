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
        BCBooruHost(name: "Yande.re", type: .Moebooru, pagePostLimit: 40, url: "http://yande.re/", maximumRating: .Explicit),
        BCBooruHost(name: "Danbooru", type: .Danbooru, pagePostLimit: 40, url: "http://danbooru.donmai.us/", maximumRating: .Explicit),
        BCBooruHost(name: "Konachan", type: .Moebooru, pagePostLimit: 40, url: "http://konachan.net/", maximumRating: .Explicit),
        BCBooruHost(name: "Gelbooru", type: .Gelbooru, pagePostLimit: 40, url: "http://gelbooru.com/", maximumRating: .Explicit)
    ];
    
    /// The format for naming saved images
    var imageSaveFormat : String = "%id%(%booru%) - %tags%";
    
    /// The alpha value of a post that has already been downloaded
    var downloadedPostAlphaValue : CGFloat = 0.5;
    
    /// Should already downloaded posts be marked?
    var indicateDownloadedPosts : Bool = true;
    
    func encodeWithCoder(coder: NSCoder) {
        // Encode the preferences
        coder.encodeObject(booruHosts, forKey: "booruHosts");
        coder.encodeObject(imageSaveFormat, forKey: "imageSaveFormat");
        coder.encodeObject(indicateDownloadedPosts, forKey: "indicateDownloadedPosts");
    }
    
    required convenience init(coder decoder: NSCoder) {
        self.init();
        
        // Decode and load the preferences
        if((decoder.decodeObjectForKey("booruHosts") as? [BCBooruHost]) != nil) {
            self.booruHosts = decoder.decodeObjectForKey("booruHosts") as! [BCBooruHost];
        }
        
        if((decoder.decodeObjectForKey("imageSaveFormat") as? String) != nil) {
            self.imageSaveFormat = decoder.decodeObjectForKey("imageSaveFormat") as! String;
        }
        
        if((decoder.decodeObjectForKey("indicateDownloadedPosts") as? Bool) != nil) {
            self.indicateDownloadedPosts = decoder.decodeObjectForKey("indicateDownloadedPosts") as! Bool;
        }
    }
}
