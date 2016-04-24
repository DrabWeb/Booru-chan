//
//  BCGridStyleViewController.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa
import Alamofire

/// Controls the Grid on left and Image on right style for Booru browsing
class BCGridStyleController: NSObject {
    /// The main split view for the Grid|Image style browser
    @IBOutlet weak var mainSplitView: BCNoDividerSplitView!
    
    /// The container view for the grid of thumbnails
    @IBOutlet weak var gridContainerView: BCColoredView!
    
    /// The container view for largeImageView
    @IBOutlet weak var largeImageViewContainer: NSView!
    
    /// The image view on the right for displaying the current selected image in full size
    @IBOutlet weak var largeImageView: NSImageView!
    
    func postLoaded(post: BCBooruPost?) {
        if(post != nil) {
            largeImageView.toolTip = "\(post!.url)\n\(post!.imageSize) \(String(post!.thumbnailSize))\n\(post!.rating)\n\(post!.tags)";
            
            Alamofire.request(.GET, post!.thumbnailUrl).response { (request, response, data, error) in
                // If data isnt nil...
                if(data != nil) {
                    /// The downloaded image
                    let image : NSImage? = NSImage(data: data!);
                    
                    // If image isnt nil...
                    if(image != nil) {
                        self.largeImageView.image = image!;
                    }
                }
            }
            
            Alamofire.request(.GET, post!.imageUrl).response { (request, response, data, error) in
                // If data isnt nil...
                if(data != nil) {
                    /// The downloaded image
                    let image : NSImage? = NSImage(data: data!);
                    
                    // If image isnt nil...
                    if(image != nil) {
                        self.largeImageView.image = image!;
                    }
                }
            }
        }
    }
    
    func initialize() {
        // Set the grid container's background color
        gridContainerView.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.2);
        
        let booruUtilies : BCBooruUtilities = BCBooruUtilities();
        booruUtilies.type = .DanbooruLegacy;
        booruUtilies.baseUrl = "http://danbooru.donmai.us";
        
        booruUtilies.getPostFromId(2340518, completionHandler: postLoaded);
    }
}
