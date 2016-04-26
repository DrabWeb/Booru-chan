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
    /// A reference to the main view controller
    @IBOutlet weak var mainViewController: BCViewController!
    
    /// The main split view for the Grid|Image style browser
    @IBOutlet weak var mainSplitView: BCNoDividerSplitView!
    
    /// The container view for the grid of thumbnails
    @IBOutlet weak var gridContainerView: BCColoredView!
    
    /// The scroll view for booruCollectionView
    @IBOutlet weak var booruCollectionViewScrollView: BCActionOnScrollToBottomScrollView!
    
    /// The collection view for showing Booru items
    @IBOutlet weak var booruCollectionView: NSCollectionView!
    
    /// The container for the views to show when there are no search results
    @IBOutlet weak var noSearchResultsContainerView: NSView!
    
    /// The visual effect view for the info bar at the bottom of the Booru collection view
    @IBOutlet weak var infoBarVisualEffectView: NSVisualEffectView!
    
    /// The info label for infoBarVisualEffectView
    @IBOutlet weak var infoBarInfoLabel: NSTextField!
    
    /// The array controller for booruCollectionView
    @IBOutlet weak var booruCollectionViewArrayController: NSArrayController!
    
    /// The items from booruCollectionViewArrayController
    var booruCollectionViewArrayControllerItems: NSMutableArray = NSMutableArray();
    
    /// The container view for largeImageView
    @IBOutlet weak var largeImageViewContainer: NSView!
    
    /// The image view on the right for displaying the current selected image in full size
    @IBOutlet weak var largeImageView: NSImageView!
    
    /// The constraint for the top space for largeImageView
    @IBOutlet weak var largeImageViewTopConstraint: NSLayoutConstraint!
    
    /// The last full size image download request made by displayPostItem
    var lastDisplayRequest : Request? = nil;
    
    /// Displays the given BCBooruCollectionViewItem in the full size image view and shows it's info in the info bar. If passed nil it will but a blank iamge in the full size image view and update the info label to say "No Posts Selected"
    func displayPostItem(postItem : BCBooruCollectionViewItem?) {
        // If lastDisplayRequest isnt nil...
        if(lastDisplayRequest != nil) {
            // Cancel the last request so the image view doesnt get updated with previous requests when looking at new requests
            lastDisplayRequest!.cancel();
        }
        
        // If postItem isnt nil...
        if(postItem != nil) {
            // If we havent already loaded the thumbnail...
            if(postItem!.thumbnailImage.size == NSSize.zero) {
                // Download the post item's thumbnail image
                Alamofire.request(.GET, postItem!.representedPost!.thumbnailUrl).response { (request, response, data, error) in
                    // If data isnt nil...
                    if(data != nil) {
                        /// The downloaded image
                        let image : NSImage? = NSImage(data: data!);
                        
                        // If image isnt nil...
                        if(image != nil) {
                            // Show the thumbnail image in the full size image view
                            self.largeImageView.image = image!;
                            
                            // Cache the image in the post item
                            postItem!.thumbnailImage = image!;
                        }
                    }
                }
            }
                // If we already loaded the thumbnail...
            else {
                // Show the thumbnail image in the full size image view
                self.largeImageView.image = postItem!.thumbnailImage;
            }
            
            /// The first letter in the post item's rating
            var ratingFirstLetter : String = String(postItem!.representedPost!.rating);
            
            // Set ratingFirstLetter to the first letter in ratingFirstLetter
            ratingFirstLetter = ratingFirstLetter.substringToIndex(ratingFirstLetter.startIndex.successor());
            
            // If we havent already downloaded the post's full size image...
            if(!postItem!.finishedLoadingImage) {
                // Download the post item's full size image
                lastDisplayRequest = Alamofire.request(.GET, postItem!.representedPost!.imageUrl).response { (request, response, data, error) in
                    // If data isnt nil...
                    if(data != nil) {
                        /// The downloaded image
                        let image : NSImage? = NSImage(data: data!);
                        
                        // If image isnt nil...
                        if(image != nil) {
                            // If we finished loading the image...
                            if(postItem!.finishedLoadingImage) {
                                // Show the image in the full size image view
                                self.largeImageView.image = image!;
                                
                                // Cache the image in the post item
                                postItem!.image = image!;
                            }
                        }
                    }
                    }
                    .progress { _, totalBytesRead, totalBytesExpectedToRead in
                        /// How much percent done the download is
                        let percentFinished : Int = Int((Float(totalBytesRead) / Float(totalBytesExpectedToRead)) * 100);
                        
                        // Dispatch onto the UI queue
                        dispatch_async(dispatch_get_main_queue()) {
                            // Update the info bar label
                            self.infoBarInfoLabel.stringValue = "\(Int(postItem!.representedPost!.imageSize.width))x\(Int(postItem!.representedPost!.imageSize.height))[\(ratingFirstLetter)] \(percentFinished)%";
                        }
                        
                        // If we loaded all of the image's data...
                        if(totalBytesRead == totalBytesExpectedToRead) {
                            // Say we finished loading the image
                            postItem!.finishedLoadingImage = true;
                        }
                }
            }
            // If we have already downloaded the post item's full size image...
            else {
                // Show the cached image in the full size image view
                self.largeImageView.image = postItem!.image;
            }
            
            // Update the info label(Only called here in case the download doesnt start)
            infoBarInfoLabel.stringValue = "\(Int(postItem!.representedPost!.imageSize.width))x\(Int(postItem!.representedPost!.imageSize.height))[\(ratingFirstLetter)] 0%";
        }
        // If postItem is nil...
        else {
            // Set the info bar label to "No Posts Selected"
            infoBarInfoLabel.stringValue = "No Posts Selected";
            
            // Show a blank image in the full size image view
            largeImageView.image = NSImage();
        }
    }
    
    /// Returns the selected BCBooruCollectionViewItems from the Booru collection view
    func getSelectedBooruItems() -> [BCBooruCollectionViewItem] {
        /// The selected BCBooruCollectionViewItems
        var selectedItems : [BCBooruCollectionViewItem] = [];
        
        // For every selection index...
        for(_, currentSelectionIndex) in booruCollectionView.selectionIndexes.enumerate() {
            // Add the item at the current index to selectedItems
            selectedItems.append((booruCollectionViewArrayController.arrangedObjects as! [BCBooruCollectionViewItem])[currentSelectionIndex]);
        }
        
        // Return the selected items
        return selectedItems;
    }
    
    /// An array of all the thumbnail download requests made by searchFinished(Cleared every time searchFor is called)
    var lastThumbnailDownloadRequests : [Request] = [];
    
    /// Called when a search is finished
    func searchFinished(results: [BCBooruPost]) {
        // For every item in the search results...
        for(_, currentResult) in results.enumerate() {
            /// The new item to add to the booru collection view
            let item : BCBooruCollectionViewItem = BCBooruCollectionViewItem();
            
            // Set the item's represented post to the current result
            item.representedPost = currentResult;
            
            // Download the post's thumbnail
            lastThumbnailDownloadRequests.append(Alamofire.request(.GET, currentResult.thumbnailUrl).response { (request, response, data, error) in
                // If data isnt nil...
                if(data != nil) {
                    /// The downloaded image
                    let image : NSImage? = NSImage(data: data!);
                    
                    // If image isnt nil...
                    if(image != nil) {
                        // If there are any items in booruCollectionViewArrayController...
                        if((self.booruCollectionViewArrayController.arrangedObjects as! [AnyObject]).count > 0) {
                            // For ever item in the Booru collection view...
                            for currentIndex in 0...(self.booruCollectionViewArrayController.arrangedObjects as! [AnyObject]).count - 1 {
                                // If the current item's represented object is equal to the item we downloaded the thumbnail for...
                                if(((self.booruCollectionView.itemAtIndex(currentIndex)! as! BCBooruCollectionViewCollectionViewItem).representedObject as! BCBooruCollectionViewItem) == item) {
                                    // Update the image view of the item
                                    (self.booruCollectionView.itemAtIndex(currentIndex)! as! BCBooruCollectionViewCollectionViewItem).imageView?.image = image!;
                                    
                                    // Set the item's model's thumbnail image
                                    ((self.booruCollectionView.itemAtIndex(currentIndex)! as! BCBooruCollectionViewCollectionViewItem).representedObject as! BCBooruCollectionViewItem).thumbnailImage = image!;
                                }
                            }
                        }
                    }
                }
            });
            
            // Add the item
            self.booruCollectionViewArrayController.addObject(item);
        }
        
        // If the results are empty...
        if(results.isEmpty) {
            // Show the no search results container
            noSearchResultsContainerView.hidden = false;
        }
    }
    
    /// When we reach the bottom of the Booru collection view...
    func reachedBottomOfBooruCollectionView() {
        // If the last search of the current searching Booru isnt blank...
        if(mainViewController.currentSelectedSearchingBooru?.utilties.lastSearch != "") {
            // Add the next page of results to the Booru collection view
            mainViewController.currentSelectedSearchingBooru!.utilties.getPostsFromSearch(mainViewController.currentSelectedSearchingBooru!.utilties.lastSearch, limit: mainViewController.currentSelectedSearchingBooru!.utilties.lastSearchLimit, page: mainViewController.currentSelectedSearchingBooru!.utilties.lastSearchPage + 1, completionHandler: searchFinished);
        }
    }
    
    /// Clears the Booru collection view, searches for the given tags and shows the results
    func searchFor(searchString : String) {
        // Deselect all posts
        booruCollectionView.deselectAll(self);
        
        // Disable the reached bottom action from being called
        booruCollectionViewScrollView.reachedBottomAction = nil;
        
        // Hide the no search results container
        noSearchResultsContainerView.hidden = true;
        
        // Clear the Booru collection view
        booruCollectionViewArrayController.removeObjects(booruCollectionViewArrayController.arrangedObjects as! [AnyObject]);
        
        // Clear the full size image view
        largeImageView.image = NSImage();
        
        // For every item in lastThumbnailDownloadRequests...
        for(_, currentRequest) in lastThumbnailDownloadRequests.enumerate() {
            // Cancel the current thumbnail download request
            currentRequest.cancel();
        }
        
        // Clear lastThumbnailDownloadRequests
        lastThumbnailDownloadRequests.removeAll();
        
        // Search for the given tags
        // If currentSelectedSearchingBooru isnt nil...
        if(mainViewController.currentSelectedSearchingBooru != nil) {
            // Search for the given tags
            mainViewController.currentSelectedSearchingBooru!.utilties.getPostsFromSearch(searchString, limit: mainViewController.currentSelectedSearchingBooru!.pagePostLimit, page: 1, completionHandler: searchFinished);
        }
        // If currentSelectedSearchingBooru is nil...
        else {
            // Print that currentSelectedSearchingBooru is nil
            print("BCGridStyleViewController: currentSelectedSearchingBooru is nil, cant search");
        }
        
        // Enable the reached bottom action
        booruCollectionViewScrollView.reachedBottomAction = Selector("reachedBottomOfBooruCollectionView");
    }
    
    /// Is the Booru collection view open?
    var booruCollectionViewOpen : Bool = true;
    
    /// The previous size of the Booru collection view(Before it was hidden)
    var booruCollectionViewPreviousSize : CGFloat = 0;
    
    /// Toggles the visibility of the booru collection view
    func toggleBooruCollectionView() {
        // Toggle booruCollectionViewOpen
        booruCollectionViewOpen = !booruCollectionViewOpen;
        
        // If the Booru collection view is now open...
        if(booruCollectionViewOpen) {
            // Show the Booru collection view
            showBooruCollectionView();
        }
        // If the Booru collection view is now closed...
        else {
            // Hide the Booru collection view
            hideBooruCollectionView();
        }
    }
    
    /// Hides the Booru collection view
    func hideBooruCollectionView() {
        // Store the Booru collection view's size
        booruCollectionViewPreviousSize = mainSplitView.subviews[0].frame.width;
        
        // Hide the Booru collection view
        mainSplitView.subviews[0].hidden = true;
        
        // Set the position of the Booru collection view divider to 0
        mainSplitView.setPosition(0, ofDividerAtIndex: 0);
    }
    
    /// Shows the Booru collection view
    func showBooruCollectionView() {
        // Show the Booru collection view
        mainSplitView.subviews[0].hidden = false;
        
        // Restore the Booru collection view's size
        mainSplitView.setPosition(booruCollectionViewPreviousSize, ofDividerAtIndex: 0);
    }
    
    /// Sets up the menu items for this controller
    func setupMenuItems() {
        // Setup the menu items
        // Set the targets
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).menuItemTogglePostBrowser.target = self;
        
        // Set the actions
        (NSApplication.sharedApplication().delegate as! BCAppDelegate).menuItemTogglePostBrowser.action = Selector("toggleBooruCollectionView");
    }
    
    func initialize() {
        // Set the grid container's background color
        gridContainerView.backgroundColor = NSColor(calibratedWhite: 0, alpha: 0.2);
        
        // Set the Booru collection view's item prototype
        booruCollectionView.itemPrototype = NSStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateControllerWithIdentifier("booruCollectionViewItem") as! BCBooruCollectionViewCollectionViewItem;
        
        // Set the minimum and maximum item sizes
        booruCollectionView.minItemSize = NSSize(width: 150, height: 150);
        booruCollectionView.maxItemSize = NSSize(width: 200, height: 200);
        
        // Setup the menu items
        setupMenuItems();
        
        // Style the visual effect views
        infoBarVisualEffectView.material = .Dark;
        
        /// The options for the Booru collection view selection observing
        let options = NSKeyValueObservingOptions([.New, .Old]);
        
        // Subscribe to when the Booru collection view's selection changes
        self.booruCollectionView.addObserver(self, forKeyPath: "selectionIndexes", options: options, context: nil);
        
        // Set the target and action to use when the user reaches the bottom of the Booru collection view
        booruCollectionViewScrollView.reachedBottomTarget = self;
        booruCollectionViewScrollView.reachedBottomAction = Selector("reachedBottomOfBooruCollectionView");
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // If the keyPath is the one for the Booru collection view selection...
        if(keyPath == "selectionIndexes") {
            // If we selected any items...
            if(booruCollectionView.selectionIndexes.firstIndex != NSNotFound) {
                /// The selected post item
                let selectedPostItem : BCBooruCollectionViewItem? = (booruCollectionView.itemAtIndex(booruCollectionView.selectionIndexes.firstIndex)?.representedObject as? BCBooruCollectionViewItem);
                
                // Show the selected post item
                displayPostItem(selectedPostItem);
            }
            // If we deselected all the items...
            else {
                // Show a nil post item
                displayPostItem(nil);
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
