//
//  BCPreferencesObject.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-25.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa

class BCPreferencesObject: NSObject, NSCoding {
    /// The Booru hosts the user has added
    // REMINDER: Set this back to init as [] when you can set your Boorus in preferences
    var booruHosts : [BCBooruHost] = [BCBooruHost(name: "Yande.re", type: .Moebooru, pagePostLimit: 40, url: "http://yande.re/"), BCBooruHost(name: "Danbooru", type: .Danbooru, pagePostLimit: 40, url: "http://danbooru.donmai.us/"), BCBooruHost(name: "Konachan", type: .Moebooru, pagePostLimit: 40, url: "http://konachan.net/"), BCBooruHost(name: "Gelbooru", type: .Gelbooru, pagePostLimit: 40, url: "http://gelbooru.com/")];
    
    /// The format for naming saved images
    var imageSaveFormat : String = "%id% - %tags%";
    
    func encodeWithCoder(coder: NSCoder) {
        // Encode the preferences
        coder.encodeObject(booruHosts, forKey: "booruHosts");
        coder.encodeObject(imageSaveFormat, forKey: "imageSaveFormat");
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
    }
}
