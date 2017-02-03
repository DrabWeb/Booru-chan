//
//  BCGridStyleViewController.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//

import Cocoa
import Alamofire

/// Controls the Grid on left and Image on right style for Booru browsing
class BCGridStyleController: NSObject, NSCollectionViewDelegate {
    /// A reference to the main view controller
    @IBOutlet weak var mainViewController: BCViewController!
    
    /// The controller for the tag list table view
    @IBOutlet weak var tagListController: BCGridStyleTagListTableViewController!
    
    /// The main split view for the Grid|Image style browser
    @IBOutlet weak var mainSplitView: BCNoDividerSplitView!
    
    /// The container view for the grid of thumbnails
    @IBOutlet weak var gridContainerView: NSVisualEffectView!
    
    /// The visual effect view for the background of the grid
    @IBOutlet weak var gridBackgroundVisualEffectView: NSVisualEffectView!
    
    /// The scroll view for booruCollectionView
    @IBOutlet weak var booruCollectionViewScrollView: BCActionOnScrollToBottomScrollView!
    
    /// The collection view for showing Booru items
    @IBOutlet weak var booruCollectionView: NSCollectionView!
    
    /// The minimum height constraint for booruCollectionView
    @IBOutlet weak var booruCollectionViewContainerMinimumHeightConstraint: NSLayoutConstraint!
    
    /// The bottom constraint for booruCollectionViewScrollView
    @IBOutlet weak var booruCollectionViewScrollViewBottomConstraint: NSLayoutConstraint!
    
    /// The container for the views to show when there are no search results
    @IBOutlet weak var noSearchResultsContainerView: NSView!
    
    /// The visual effect view for the info bar at the bottom of the Booru collection view
    @IBOutlet weak var infoBarVisualEffectView: NSVisualEffectView!
    
    /// The info label for infoBarVisualEffectView
    @IBOutlet weak var infoBarInfoLabel: NSTextField!
    
    /// The array controller for booruCollectionView
    @IBOutlet weak var booruCollectionViewArrayController: NSArrayController!
    
    /// The split view for the left items(The Booru collection view and the tag list)
    @IBOutlet weak var leftSplitView: BCNoDividerSplitView!
    
    /// The items from booruCollectionViewArrayController
    var booruCollectionViewArrayControllerItems: NSMutableArray = NSMutableArray();
    
    /// The scroll view for imageView
    @IBOutlet weak var imageViewScrollView: NSScrollView!
    
    /// The image view on the right for displaying the current selected image in full size
    @IBOutlet weak var imageView: NSImageView!
    
    /// The last full size image download request made by displayPostItem
    var lastDisplayRequest : Request? = nil;
    
    /// Displays the given BCBooruCollectionViewItem in the full size image view and shows it's info in the info bar. If passed nil it will but a blank iamge in the full size image view and update the info label to say "No Posts Selected"
    func displayPostItem(_ postItem : BCBooruCollectionViewItem?) {
        // If lastDisplayRequest isnt nil...
        if(lastDisplayRequest != nil) {
            // Cancel the last request so the image view doesnt get updated with previous requests when looking at new requests
            lastDisplayRequest!.cancel();
        }
        
        // If postItem isnt nil...
        if(postItem != nil) {
            // Reset the zoom on the large image view
            resetZoom(false);
            
            // If we havent already loaded the thumbnail...
            if(postItem!.thumbnailImage.size == NSSize.zero) {
                // Download the post item's thumbnail image
                Alamofire.request(postItem!.representedPost!.thumbnailUrl)
                    .responseData { response in
                        // If data isnt nil...
                        if let data = response.result.value {
                            /// The downloaded image
                            let image : NSImage? = NSImage(data: data);
                            
                            // If image isnt nil...
                            if(image != nil) {
                                // Show the thumbnail image in the full size image view
                                self.imageView.image = image!;
                            
                                // Cache the image in the post item
                                postItem!.thumbnailImage = image!;
                            }
                        }
                };
            }
            // If we already loaded the thumbnail...
            else {
                // Show the thumbnail image in the full size image view
                self.imageView.image = postItem!.thumbnailImage;
            }
            
            /// The first letter in the post item's rating
            var ratingFirstLetter : String = String(describing: postItem!.representedPost!.rating);
            
            // Set ratingFirstLetter to the first letter in ratingFirstLetter
            ratingFirstLetter = ratingFirstLetter.substring(to: ratingFirstLetter.characters.index(after: ratingFirstLetter.startIndex));
            
            // Capitalize ratingFirstLetter
            ratingFirstLetter = ratingFirstLetter.uppercased();
            
            // If we havent already downloaded the post's full size image...
            if(!postItem!.finishedLoadingImage) {
                // Download the post item's full size image
                lastDisplayRequest = Alamofire.request(postItem!.representedPost!.imageUrl)
                    .responseData { response in
                        // If data isnt nil...
                        if let data = response.result.value {
                            /// The downloaded image
                            let image : NSImage? = NSImage(data: data);
                            
                            // If image isnt nil...
                            if(image != nil) {
                                // If we finished loading the image...
                                if(postItem!.finishedLoadingImage) {
                                    // Show the image in the full size image view
                                    self.imageView.image = image!;
                                    
                                    // Cache the image in the post item
                                    postItem!.image = image!;
                                    
                                    // Enable/disable animated GIF displaying based on if the image is animated
                                    self.imageView.canDrawSubviewsIntoLayer = postItem!.representedPost!.animated;
                                    self.imageView.animates = postItem!.representedPost!.animated;
                                }
                            }
                        }
                    }
                    .downloadProgress { progress in
                        /// How much percent done the download is
                        let percentFinished : Int = Int(progress.fractionCompleted * Double(100));
                        
                        // Dispatch onto the UI queue
                        DispatchQueue.main.async() {
                            // Update the info bar label
                            self.infoBarInfoLabel.stringValue = "\(Int(postItem!.representedPost!.imageSize.width))x\(Int(postItem!.representedPost!.imageSize.height))[\(ratingFirstLetter)] \(percentFinished)%";
                        }
                        
                        // If we loaded all of the image's data...
                        if(progress.fractionCompleted == Double(1)) {
                            // Say we finished loading the image
                            postItem!.finishedLoadingImage = true;
                        }
                };
            }
            // If we have already downloaded the post item's full size image...
            else {
                // Show the cached image in the full size image view
                self.imageView.image = postItem!.image;
                
                // Enable/disable animated GIF displaying based on if the image is animated
                imageView.canDrawSubviewsIntoLayer = postItem!.representedPost!.animated;
                imageView.animates = postItem!.representedPost!.animated;
            }
            
            // Update the info label(Only called here in case the download doesnt start)
            infoBarInfoLabel.stringValue = "\(Int(postItem!.representedPost!.imageSize.width))x\(Int(postItem!.representedPost!.imageSize.height))[\(ratingFirstLetter)] 0%";
            
            // If the post item's image finished loading...
            if(postItem!.finishedLoadingImage) {
                // Update the info label to say 100%
                infoBarInfoLabel.stringValue = "\(Int(postItem!.representedPost!.imageSize.width))x\(Int(postItem!.representedPost!.imageSize.height))[\(ratingFirstLetter)] 100%";
            }
        }
        // If postItem is nil...
        else {
            // Set the info bar label to "No Posts Selected"
            infoBarInfoLabel.stringValue = "No Posts Selected";
            
            // Show a blank image in the full size image view
            imageView.image = NSImage();
        }
        
        // If the post item and it's post arent nil...
        if(postItem != nil && postItem?.representedPost != nil) {
            // Load the post's tags into the tags table view
            tagListController.displayTagsFromPost(postItem!.representedPost!);
        }
        // If the post item or post is nil...
        else {
            // Display a blank item in the tag list(So it just clears the table view)
            tagListController.displayTagsFromPost(BCBooruPost());
        }
    }
    
    /// Zooms in on the large image view
    func zoomIn() {
        // Zoom in
        imageViewScrollView.magnification += 0.5;
    }
    
    /// Zooms out of the large image view
    func zoomOut() {
        // Zoom out
        imageViewScrollView.magnification -= 0.5;
    }
    
    /// Resets the zoom on the large image view(Animates if animate is true)
    func resetZoom(_ animate : Bool) {
        (animate ? imageViewScrollView.animator() : imageViewScrollView).magnification = 1;
    }
    
    /// Calls resetZoom(true)
    func resetZoomWithAnimation() {
        resetZoom(true);
    }
    
    /// Returns the selected BCBooruCollectionViewItems from the Booru collection view
    func getSelectedBooruItems() -> [BCBooruCollectionViewItem] {
        /// The selected BCBooruCollectionViewItems
        var selectedItems : [BCBooruCollectionViewItem] = [];
        
        // For every selection index...
        for(_, currentSelectionIndex) in booruCollectionView.selectionIndexes.enumerated() {
            // Add the item at the current index to selectedItems
            selectedItems.append((booruCollectionViewArrayController.arrangedObjects as! [BCBooruCollectionViewItem])[currentSelectionIndex]);
        }
        
        // Return the selected items
        return selectedItems;
    }
    
    /// An array of all the thumbnail download requests made by searchFinished(Cleared every time searchFor is called)
    var lastThumbnailDownloadRequests : [Request] = [];
    
    /// Have we already added the no more results item to this search?
    var addedNoMoreResultsItem : Bool = false;
    
    /// Called when a search is finished
    func searchFinished(_ results: [BCBooruPost]) {
        // For every item in the search results...
        for(_, currentResult) in results.enumerated() {
            /// The new item to add to the booru collection view
            let item : BCBooruCollectionViewItem = BCBooruCollectionViewItem();
            
            // Set the item's represented post to the current result
            item.representedPost = currentResult;
            
            /// The image extensions that are allowed to be viewed
            let imageExtension : [String] = ["png", "jpg", "jpeg", "gif"];
            
            // If the result's image and thumbnail URL are an image...
            if(imageExtension.contains(NSString(string: item.representedPost!.imageUrl).pathExtension) && imageExtension.contains(NSString(string: item.representedPost!.thumbnailUrl).pathExtension)) {
                // Download the post's thumbnail
                lastThumbnailDownloadRequests.append(Alamofire.request(currentResult.thumbnailUrl)
                    .responseData { response in
                        // If data isnt nil...
                        if let data = response.result.value {
                            /// The downloaded image
                            let image : NSImage? = NSImage(data: data);
                            
                            // If image isnt nil...
                            if(image != nil) {
                                // If there are any items in booruCollectionViewArrayController...
                                if((self.booruCollectionViewArrayController.arrangedObjects as! [AnyObject]).count > 0) {
                                    // For ever item in the Booru collection view...
                                    for currentIndex in 0...(self.booruCollectionViewArrayController.arrangedObjects as! [AnyObject]).count - 1 {
                                        // If the current item's represented object is equal to the item we downloaded the thumbnail for...
                                        if(((self.booruCollectionView.item(at: currentIndex)! as! BCBooruCollectionViewCollectionViewItem).representedObject as! BCBooruCollectionViewItem) == item) {
                                            // Update the image view of the item
                                            (self.booruCollectionView.item(at: currentIndex)! as! BCBooruCollectionViewCollectionViewItem).imageView?.image = image!;
                                            
                                            // Set the item's model's thumbnail image
                                            ((self.booruCollectionView.item(at: currentIndex)! as! BCBooruCollectionViewCollectionViewItem).representedObject as! BCBooruCollectionViewItem).thumbnailImage = image!;
                                        }
                                    }
                                }
                            }
                        }
                });
                
                // Add the item
                self.booruCollectionViewArrayController.addObject(item);
            }
        }
        
        // If the results are empty and booruCollectionViewArrayController is empty...
        if(results.isEmpty && (booruCollectionViewArrayController.arrangedObjects as! [AnyObject]).isEmpty) {
            // Show the no search results container
            noSearchResultsContainerView.isHidden = false;
        }
        // If just the results are empty and we havent added the no more results item...
        else if(results.isEmpty && !addedNoMoreResultsItem) {
            // Add the no more results item to the end of the Booru collection view
            /// The item to show the no more results item
            let item: BCBooruCollectionViewItem = BCBooruCollectionViewItem();
            
            // Set the item's post to a blank post
            item.representedPost = BCBooruPost();
            
            // Say the image has been loaded so it doesnt waste anything trying to load nothing
            item.finishedLoadingImage = true;
            
            // Set the item's thumbnail image to the no more results image
            item.thumbnailImage = NSImage(named: "No More Results")!;
            
            // Set that the item is a "No More Results" item
            item.noMoreResultsItem = true;
            
            // Add the item to the Booru collection view
            self.booruCollectionViewArrayController.addObject(item);
            
            // Say we added the no more results item
            addedNoMoreResultsItem = true;
        }
        
        // Reload the downloaded indicators
        reloadDownloadedIndicators();
    }
    
    /// Updates the downloaded indicators for all the posts in the Booru collection view
    func reloadDownloadedIndicators() {
        // If we said to indicate downloaded posts...
        if((NSApplication.shared().delegate as! BCAppDelegate).preferences.indicateDownloadedPosts) {
            // For every item in the Booru collection view...
            for(_, currentItem) in (booruCollectionViewArrayController.arrangedObjects as! [BCBooruCollectionViewItem]).enumerated() {
                // Set the item's alpha value to downloadedPostAlphaValue if it has been downloaded
                if(mainViewController.currentSelectedSearchingBooru!.hasDownloadedId(currentItem.representedPost!.id)) {
                    currentItem.alphaValue = (NSApplication.shared().delegate as! BCAppDelegate).preferences.downloadedPostAlphaValue;
                }
            }
            
            // Reload the collection view
            booruCollectionView.itemPrototype = NSStoryboard(name: "Main", bundle: Bundle.main).instantiateController(withIdentifier: "booruCollectionViewItem") as! BCBooruCollectionViewCollectionViewItem;
        }
    }
    
    /// When we reach the bottom of the Booru collection view...
    func reachedBottomOfBooruCollectionView() {
        // If the last search of the current searching Booru isnt blank...
        if((booruCollectionViewArrayController.arrangedObjects as! [AnyObject]).count > 0) {
            // Add the next page of results to the Booru collection view
            _ = mainViewController.currentSelectedSearchingBooru!.utilties?.getPostsFromSearch(mainViewController.currentSelectedSearchingBooru!.utilties.lastSearch, limit: mainViewController.currentSelectedSearchingBooru!.utilties.lastSearchLimit, page: mainViewController.currentSelectedSearchingBooru!.utilties.lastSearchPage + 1, completionHandler: searchFinished);
        }
    }
    
    /// Clears the Booru collection view, searches for the given tags and shows the results
    func searchFor(_ searchString : String) {
        // Deselect all posts
        booruCollectionView.deselectAll(self);
        
        // Disable the reached bottom action from being called
        booruCollectionViewScrollView.reachedBottomAction = nil;
        
        // Hide the no search results container
        noSearchResultsContainerView.isHidden = true;
        
        // Clear the Booru collection view
        booruCollectionViewArrayController.remove(contentsOf: booruCollectionViewArrayController.arrangedObjects as! [AnyObject]);
        
        // Say we havent added the no more results item
        addedNoMoreResultsItem = false;
        
        // Clear the full size image view
        imageView.image = NSImage();
        
        // For every item in lastThumbnailDownloadRequests...
        for(_, currentRequest) in lastThumbnailDownloadRequests.enumerated() {
            // Cancel the current thumbnail download request
            currentRequest.cancel();
        }
        
        // Clear lastThumbnailDownloadRequests
        lastThumbnailDownloadRequests.removeAll();
        
        // Search for the given tags
        // If currentSelectedSearchingBooru isnt nil...
        if(mainViewController.currentSelectedSearchingBooru != nil) {
            // Search for the given tags
            _ = mainViewController.currentSelectedSearchingBooru!.utilties?.getPostsFromSearch(searchString, limit: mainViewController.currentSelectedSearchingBooru!.pagePostLimit, page: 1, completionHandler: searchFinished);
        }
        // If currentSelectedSearchingBooru is nil...
        else {
            // Print that currentSelectedSearchingBooru is nil
            print("BCGridStyleViewController: currentSelectedSearchingBooru is nil, cant search");
        }
        
        // Enable the reached bottom action
        booruCollectionViewScrollView.reachedBottomAction = #selector(BCGridStyleController.reachedBottomOfBooruCollectionView);
    }
    
    /// Is the tag list open?
    var tagListOpen : Bool = true;
    
    /// Toggles the visibility of the tag list
    func toggleTagList() {
        // Toggle tagListOpen
        tagListOpen = !tagListOpen;
        
        // If the tag list is now open...
        if(tagListOpen) {
            // Show the tag list
            showTagList();
        }
        // If the tag list is now closed...
        else {
            // Hide the tag list
            hideTagList();
        }
    }
    
    /// Hides the tag list
    func hideTagList() {
        // Hide the tag list
        leftSplitView.subviews[1].isHidden = true;
    }
    
    /// Shows the tag list
    func showTagList() {
        // Show the tag list
        leftSplitView.subviews[1].isHidden = false;
    }
    
    var infoBarOpen : Bool = true;
    
    func toggleInfoBar() {
        infoBarOpen = !infoBarOpen;
        
        if(infoBarOpen) {
            showInfoBar();
        }
        else {
            hideInfoBar();
        }
    }
    
    func hideInfoBar() {
        infoBarVisualEffectView.isHidden = true;
        booruCollectionViewContainerMinimumHeightConstraint.constant = 37;
        booruCollectionViewScrollViewBottomConstraint.constant = -22;
    }
    
    func showInfoBar() {
        infoBarVisualEffectView.isHidden = false;
        booruCollectionViewContainerMinimumHeightConstraint.constant = 59;
        booruCollectionViewScrollViewBottomConstraint.constant = 0;
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
        mainSplitView.subviews[0].isHidden = true;
        
        // Set the position of the Booru collection view divider to 0
        mainSplitView.setPosition(0, ofDividerAt: 0);
    }
    
    /// Shows the Booru collection view
    func showBooruCollectionView() {
        // Show the Booru collection view
        mainSplitView.subviews[0].isHidden = false;
        
        // Restore the Booru collection view's size
        mainSplitView.setPosition(booruCollectionViewPreviousSize, ofDividerAt: 0);
    }
    
    func initialize() {
        // Set the Booru collection view's item prototype
        booruCollectionView.itemPrototype = NSStoryboard(name: "Main", bundle: Bundle.main).instantiateController(withIdentifier: "booruCollectionViewItem") as! BCBooruCollectionViewCollectionViewItem;
        
        // Set the minimum and maximum item sizes
        booruCollectionView.minItemSize = NSSize(width: 150, height: 150);
        booruCollectionView.maxItemSize = NSSize(width: 200, height: 200);
        
        /// The options for the Booru collection view selection observing
        let options = NSKeyValueObservingOptions([.new, .old]);
        
        // Subscribe to when the Booru collection view's selection changes
        self.booruCollectionView.addObserver(self, forKeyPath: "selectionIndexes", options: options, context: nil);
        
        // Set the target and action to use when the user reaches the bottom of the Booru collection view
        booruCollectionViewScrollView.reachedBottomTarget = self;
        booruCollectionViewScrollView.reachedBottomAction = #selector(BCGridStyleController.reachedBottomOfBooruCollectionView);
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // If the keyPath is the one for the Booru collection view selection...
        if(keyPath == "selectionIndexes") {
            // If we selected any items...
            if(booruCollectionView.selectionIndexes.first != nil) {
                /// The selected post item
                let selectedPostItem : BCBooruCollectionViewItem? = (booruCollectionView.item(at: booruCollectionView.selectionIndexes.first!)?.representedObject as? BCBooruCollectionViewItem);
                
                // Show the selected post item
                displayPostItem(selectedPostItem);
            }
            // If we deselected all the items...
            else {
                // Show a nil post item
                displayPostItem(nil);
            }
            
            mainViewController.updateTitle();
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
    
    /// How opaque this item should be in the grid(Used to represent when you have downloaded something before)
    var alphaValue : CGFloat = 1;
    
    /// Is this an item that shows that there is no more results?
    var noMoreResultsItem : Bool = false;
    
    /// The post this item represents
    var representedPost : BCBooruPost? = nil;
}
