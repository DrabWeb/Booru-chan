//
//  BCBooruCollectionViewCollectionViewItem.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-24.
//

import Cocoa

class BCBooruCollectionViewCollectionViewItem: NSCollectionViewItem {
    
    /// Returns the URL to this post
    var getUrl : String {
        return (self.representedObject as! BCBooruCollectionViewItem).representedPost!.url;
    }
    
    /// Returns the URL to this post's image
    var getImageUrl : String {
        return (self.representedObject as! BCBooruCollectionViewItem).representedPost!.imageUrl;
    }
    
    override func rightMouseDown(theEvent: NSEvent) {
        /// The menu to show when the user right clicks this item
        let menu : NSMenu = NSMenu();
        
        // Deselect all the items in the Booru collection view
        self.collectionView.deselectAll(self);
        
        // Select this item
        self.selected = true;
        
        // Add the menu items to the menu
        menu.addItemWithTitle("Open In Browser", action: Selector("openInBrowser"), keyEquivalent: "");
        menu.addItemWithTitle("Copy URL", action: Selector("copyUrlToClipboard"), keyEquivalent: "");
        menu.addItemWithTitle("Copy Image URL", action: Selector("copyImageUrlToClipboard"), keyEquivalent: "");
        
        // Show the menu
        NSMenu.popUpContextMenu(menu, withEvent: theEvent, forView: self.view);
    }
    
    /// Opens this post in the browser
    func openInBrowser() {
        // Open this item's post's URL in the browser
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: getUrl)!);
    }
    
    /// Copys the URL of this post to the clipboard
    func copyUrlToClipboard() {
        // Add the string type to the general pasteboard
        NSPasteboard.generalPasteboard().declareTypes([NSStringPboardType], owner: nil);
        
        // Set the string of the general pasteboard to this item's post's URL
        NSPasteboard.generalPasteboard().setString(getUrl, forType: NSStringPboardType);
    }
    
    /// Copys the URL of this post to the clipboard
    func copyImageUrlToClipboard() {
        // Add the string type to the general pasteboard
        NSPasteboard.generalPasteboard().declareTypes([NSStringPboardType], owner: nil);
        
        // Set the string of the general pasteboard to this item's post's image's URL
        NSPasteboard.generalPasteboard().setString(getImageUrl, forType: NSStringPboardType);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Bind the alpha value
        self.imageView?.bind("alphaValue", toObject: self, withKeyPath: "representedObject.alphaValue", options: nil);
    }
}
