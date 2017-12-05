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
    
    override func rightMouseDown(with theEvent: NSEvent) {
        /// The menu to show when the user right clicks this item
        let menu : NSMenu = NSMenu();
        
        // Deselect all the items in the Booru collection view
        self.collectionView?.deselectAll(self);
        
        // Select this item
        self.isSelected = true;
        
        // Add the menu items to the menu
        menu.addItem(withTitle: "Open In Browser", action: #selector(BCBooruCollectionViewCollectionViewItem.openInBrowser), keyEquivalent: "");
        menu.addItem(withTitle: "Copy URL", action: #selector(BCBooruCollectionViewCollectionViewItem.copyUrlToClipboard), keyEquivalent: "");
        menu.addItem(withTitle: "Copy Image URL", action: #selector(BCBooruCollectionViewCollectionViewItem.copyImageUrlToClipboard), keyEquivalent: "");
        
        // Show the menu
        NSMenu.popUpContextMenu(menu, with: theEvent, for: self.view);
    }
    
    /// Opens this post in the browser
    @objc func openInBrowser() {
        // Open this item's post's URL in the browser
        NSWorkspace.shared.open(URL(string: getUrl)!);
    }
    
    /// Copys the URL of this post to the clipboard
    @objc func copyUrlToClipboard() {
        // Add the string type to the general pasteboard
        NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil);
        
        // Set the string of the general pasteboard to this item's post's URL
        NSPasteboard.general.setString(getUrl, forType: NSPasteboard.PasteboardType.string);
    }
    
    /// Copys the URL of this post to the clipboard
    @objc func copyImageUrlToClipboard() {
        // Add the string type to the general pasteboard
        NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil);
        
        // Set the string of the general pasteboard to this item's post's image's URL
        NSPasteboard.general.setString(getImageUrl, forType: NSPasteboard.PasteboardType.string);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Bind the alpha value
        self.imageView?.bind(NSBindingName(rawValue: "alphaValue"), to: self, withKeyPath: "representedObject.alphaValue", options: nil);
    }
}
