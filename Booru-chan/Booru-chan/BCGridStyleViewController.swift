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
    
    func searchFinished(results: [BCBooruPost]) {
        print(results);
    }
    
    func postFinished(post: BCBooruPost?) {
        print(post);
    }
    
    func initialize() {
        // Set the grid container's background color
        gridContainerView.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.2);
        
        let booruUtilies : BCBooruUtilities = BCBooruUtilities();
        booruUtilies.type = .Gelbooru;
        booruUtilies.baseUrl = "http://gelbooru.com";
        
        booruUtilies.getPostFromId(1, completionHandler: postFinished);
        booruUtilies.getPostsFromSearch("dress rating:safe", limit: 10, page: 0, completionHandler: searchFinished);
    }
}
