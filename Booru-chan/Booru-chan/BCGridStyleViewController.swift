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
class BCGridStyleController: NSObject, NSCollectionViewDelegate {
    /// The main split view for the Grid|Image style browser
    @IBOutlet weak var mainSplitView: BCNoDividerSplitView!
    
    /// The container view for the grid of thumbnails
    @IBOutlet weak var gridContainerView: BCColoredView!
    
    /// The scroll view for booruCollectionView
    @IBOutlet weak var booruCollectionViewScrollView: NSScrollView!
    
    /// The collection view for showing Booru items
    @IBOutlet weak var booruCollectionView: NSCollectionView!
    
    /// The array controller for booruCollectionView
    @IBOutlet weak var booruCollectionViewArrayController: NSArrayController!
    
    /// The items from booruCollectionViewArrayController
    var booruCollectionViewArrayControllerItems: NSMutableArray = NSMutableArray();
    
    /// The container view for largeImageView
    @IBOutlet weak var largeImageViewContainer: NSView!
    
    /// The image view on the right for displaying the current selected image in full size
    @IBOutlet weak var largeImageView: NSImageView!
    
    func searchFinished(results: [BCBooruPost]) {
        for(currentIndex, currentResult) in results.enumerate() {
            let item : BCBooruCollectionViewItem = BCBooruCollectionViewItem();
            item.representedPost = currentResult;
            
            Alamofire.request(.GET, currentResult.thumbnailUrl).response { (request, response, data, error) in
                // If data isnt nil...
                if(data != nil) {
                    /// The downloaded image
                    let image : NSImage? = NSImage(data: data!);
                    
                    // If image isnt nil...
                    if(image != nil) {
                        // Update the image view
                        (self.booruCollectionView.itemAtIndex(currentIndex) as! BCBooruCollectionViewCollectionViewItem).imageView?.image = image!;
                        
                        // Set the model's thumbnail image
                        ((self.booruCollectionView.itemAtIndex(currentIndex) as! BCBooruCollectionViewCollectionViewItem).representedObject as! BCBooruCollectionViewItem).thumbnailImage = image!;
                    }
                }
            }
            
            self.booruCollectionViewArrayController.addObject(item);
        }
    }
    
    func initialize() {
        // Set the grid container's background color
        gridContainerView.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.2);
        
        // Set the Booru collection view's item prototype
        booruCollectionView.itemPrototype = NSStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateControllerWithIdentifier("booruCollectionViewItem") as! BCBooruCollectionViewCollectionViewItem;
        
        // Set the minimum and maximum item sizes
        booruCollectionView.minItemSize = NSSize(width: 150, height: 150);
        booruCollectionView.maxItemSize = NSSize(width: 200, height: 200);
        
        /// The options for the Booru collection view selection observing
        let options = NSKeyValueObservingOptions([.New, .Old]);
        
        // Subscribe to when the Booru collection view's selection changes
        self.booruCollectionView.addObserver(self, forKeyPath: "selectionIndexes", options: options, context: nil);
        
        let booruUtilies : BCBooruUtilities = BCBooruUtilities();
        booruUtilies.type = BCBooruType.Moebooru;
        booruUtilies.baseUrl = "http://yande.re";
        
        booruUtilies.getPostsFromSearch("hatsune_miku rating:safe", limit: 10, page: 0, completionHandler: searchFinished);
    }
    
    var lastDisplayRequest : Request? = nil;
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // If the keyPath is the one for the Booru collection view selection...
        if(keyPath == "selectionIndexes") {
            // If lastDisplayRequest isnt nil...
            if(lastDisplayRequest != nil) {
                // Cancel the last request so we dont have the image view flashing when new stuff loads
                lastDisplayRequest!.cancel();
            }
            
            /// The selected post
            let selectedPostItem : BCBooruCollectionViewItem = (booruCollectionView.itemAtIndex(booruCollectionView.selectionIndexes.firstIndex)?.representedObject as! BCBooruCollectionViewItem);
            
            // If we havent already loaded the thumbnail...
            if(selectedPostItem.thumbnailImage.size == NSSize.zero) {
                // Show the selected post's image
                Alamofire.request(.GET, selectedPostItem.representedPost!.thumbnailUrl).response { (request, response, data, error) in
                    // If data isnt nil...
                    if(data != nil) {
                        /// The downloaded image
                        let image : NSImage? = NSImage(data: data!);
                        
                        // If image isnt nil...
                        if(image != nil) {
                            // Show the thumbnail image in the full size image view
                            self.largeImageView.image = image!;
                            
                            // Cache the image in the post item
                            selectedPostItem.thumbnailImage = image!;
                        }
                    }
                }
            }
            // If we already loaded the thumbnail...
            else {
                // Show the thumbnail image in the full size image view
                self.largeImageView.image = selectedPostItem.thumbnailImage;
            }
            
            if(!selectedPostItem.finishedLoadingImage) {
                lastDisplayRequest = Alamofire.request(.GET, selectedPostItem.representedPost!.imageUrl).response { (request, response, data, error) in
                    // If data isnt nil...
                    if(data != nil) {
                        /// The downloaded image
                        let image : NSImage? = NSImage(data: data!);
                        
                        // If image isnt nil...
                        if(image != nil) {
                            // If we finished loading the image...
                            if(selectedPostItem.finishedLoadingImage) {
                                // Show the image in the full size image view
                                self.largeImageView.image = image!;
                                
                                // Cache the image in the post item
                                selectedPostItem.image = image!;
                            }
                        }
                    }
                }
                .progress { _, totalBytesRead, totalBytesExpectedToRead in
                    // If we loaded all of the image's data...
                    if(totalBytesRead == totalBytesExpectedToRead) {
                        // Say we finished loading the image
                        selectedPostItem.finishedLoadingImage = true;
                    }
                }
            }
            else {
                self.largeImageView.image = selectedPostItem.image;
            }
        }
    }
}

class BCBooruCollectionViewItem: NSObject {
    /// The thumbnail image for this item
    var thumbnailImage : NSImage = NSImage();
    
    /// The full size image(Only set if the user selected this item and it was fully loaded)
    var image : NSImage = NSImage();
    
    /// Has the image finished loading yet?
    var finishedLoadingImage : Bool = false;
    
    /// The post this item represents
    var representedPost : BCBooruPost? = nil;
}
