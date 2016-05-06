//
//  BCSBooruSearchTokenField.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-26.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa
import SwiftyJSON
import Alamofire

/// The custom NSTokenField for tag search fields
class BCBooruSearchTokenField: BCAlwaysActiveTokenField, NSTokenFieldDelegate {
    
    /// The Booru to use to get the autocompletion suggestions
    var tokenBooru : BCBooruHost? = nil;
    
    /// The last tags that were downloaded from searching
    var lastDownloadedTags : [String] = [];
    
    /// The last search that triggered a tag download
    var lastDownloadSearch : String = "";
    
    /// The last request that was made to download tag suggestions
    var lastDownloadRequest : Request? = nil;
    
    override func textDidChange(notification: NSNotification) {
        super.textDidChange(notification);
        
        // If the current token is blank or the last character in the string is a comma...
        if(self.tokens.last == "" || self.stringValue.substringFromIndex(self.stringValue.endIndex.predecessor()) == ",") {
            // Empty lastDownloadedTags
            lastDownloadedTags = [];
            
            // Stop the last tag suggestion download request
            lastDownloadRequest?.cancel();
        }
    }
    
    func tokenField(tokenField: NSTokenField, readFromPasteboard pboard: NSPasteboard) -> [AnyObject]? {
        // Return the text from pboard split at every space
        return (pboard.stringForType(NSStringPboardType)?.componentsSeparatedByString(" "));
    }
    
    func tokenField(tokenField: NSTokenField, writeRepresentedObjects objects: [AnyObject], toPasteboard pboard: NSPasteboard) -> Bool {
        // Add the string type to the pasteboard
        pboard.declareTypes([NSStringPboardType], owner: nil);
        
        /// The string to paste to the pasteboard
        var pasteString : String = "";
        
        // For every string in objects...
        for(_, currentString) in (objects as! [String]).enumerate() {
            // Add the current string with a trailing space to pasteString
            pasteString += currentString + " ";
        }
        
        // If pasteString isnt empty...
        if(pasteString != "") {
            // Remove the final trailing space from pasteString
            pasteString = pasteString.substringToIndex(pasteString.endIndex.predecessor());
        }
        
        // Paste pasteString to the pasteboard
        pboard.setString(pasteString, forType: NSStringPboardType);
        
        // Always allow copying tokens
        return true;
    }
    
    func tokenField(tokenField: NSTokenField, shouldAddObjects tokens: [AnyObject], atIndex index: Int) -> [AnyObject] {
        // Empty lastDownloadedTags
        lastDownloadedTags = [];
        
        // Return the given tokens
        return tokens;
    }
    
    func tokenField(tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>) -> [AnyObject]? {
        /// The completions for this substring
        var completions : [String] = [];
        
        // Make sure the Token Booru's cache folder exists
        tokenBooru?.createCacheFolder();
        
        // If we typed in more than one character...
        if(substring.characters.count == 1) {
            // If lastDownloadedTags is empty...
            if(lastDownloadedTags == []) {
                // If there is already a cache file for this search...
                if(NSFileManager.defaultManager().fileExistsAtPath(tokenBooru!.cacheFolderPath + substring + ".json")) {
                    // Load the results from that file
                    // Print that we are loading results from a cache file
                    Swift.print("BCBooruSearchTokenField: Loading search results cache from \"\(tokenBooru!.cacheFolderPath + substring + ".json")\"");
                    
                    // Asynchronously load the cached file
                    dispatch_async(dispatch_get_main_queue()) {
                        /// The JSON from the results cache file
                        let resultsCacheJson : JSON = JSON(data: NSFileManager.defaultManager().contentsAtPath(self.tokenBooru!.cacheFolderPath + substring + ".json")!);
                        
                        // Set lastDownloadedTags to the cached results
                        self.lastDownloadedTags = resultsCacheJson["results"].arrayObject as! [String];
                    }
                }
                // If there isnt a cache file for this search...
                else {
                    // Search for any tags with the current substring as a prefix
                    lastDownloadRequest = tokenBooru?.utilties.getTagsMatchingSearch(substring + "*", completionHandler: finishedDownloadingTags);
                }
                
                // Set lastDownloadSearch
                lastDownloadSearch = substring;
            }
        }
        
        // If tokenBooru isnt nil...
        if(tokenBooru != nil) {
            // For every tag in the Token Booru's tag search history...
            for(_, currentHistoryTag) in tokenBooru!.tagHistory.enumerate() {
                // If the current tag has the current substring as a prefix...
                if(currentHistoryTag.hasPrefix(substring)) {
                    // Add the current tag to the completions
                    completions.append(currentHistoryTag);
                }
            }
        }
        
        // For every tag in lastDownloadedTags...
        for(_, currentDownloadedTag) in lastDownloadedTags.enumerate() {
            // If the current tag has the current substring as a prefix and the tag isnt already in the completions...
            if(currentDownloadedTag.hasPrefix(substring) && !completions.contains(currentDownloadedTag)) {
                // Add the current tag to the completions
                completions.append(currentDownloadedTag);
            }
        }
        
        // Return the completions
        return completions;
    }
    
    /// Called when the tag download finishes for autocompletion suggestions
    func finishedDownloadingTags(tags : [String]) {
        // Print what tags we downloaded
        Swift.print("BCBooruSearchTokenField: Downloaded tags for completion: \(tags)");
        
        // If lastDownloadedTags is empty...
        if(lastDownloadedTags == []) {
            // Set lastDownloadedTags to the downloaded tags
            lastDownloadedTags = tags;
        }
        
        // If the tags arent empty...
        if(tags != []) {
            // If the first letter in the first element of tags is equal to the last download search(This is for safety in case another download finishes before the one we want and caches results under the wrong file, breaking those results until the cache is wiped)...
            if(tags[0].substringToIndex(tags[0].startIndex.successor()) == lastDownloadSearch) {
                // Cache the tag results
                /// The JSON to hold the results
                var tagsJson : JSON = JSON(["results":[]]);
                
                // Set the results value
                tagsJson["results"].arrayObject = tags;
                
                do {
                    // Print where we are saving the JSON
                    Swift.print("BCBooruSearchTokenField: Writing search cache to \"\((tokenBooru?.cacheFolderPath)! + lastDownloadSearch + ".json"))\"");
                    
                    // Write the JSON to a JSON file in the Token Booru's cache folder
                    try String(tagsJson).writeToFile((tokenBooru?.cacheFolderPath)! + lastDownloadSearch + ".json", atomically: true, encoding: NSUTF8StringEncoding);
                }
                catch let error as NSError {
                    // Print the error
                    Swift.print("BCBooruSearchTokenField: Failed to write JSON cache file, \(error.description)");
                }
            }
        }
    }
    
    override func awakeFromNib() {
        // Set the delegate
        self.delegate = self;
    }
}
