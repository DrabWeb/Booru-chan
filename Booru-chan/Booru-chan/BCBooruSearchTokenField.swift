//
//  BCSBooruSearchTokenField.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-26.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa

/// The custom NSTokenField for tag search fields
class BCBooruSearchTokenField: BCAlwaysActiveTokenField, NSTokenFieldDelegate {
    
    /// The Booru to use to get the autocompletion suggestions
    var tokenBooru : BCBooruHost? = nil;
    
    /// The last tags that were downloaded from searching
    var lastDownloadedTags : [String] = [];
    
    override func textDidChange(notification: NSNotification) {
        super.textDidChange(notification);
        
        // If the current token is blank or the last character in the string is a comma...
        if(self.tokens.last == "" || self.stringValue.substringFromIndex(self.stringValue.endIndex.predecessor()) == ",") {
            // Empty lastDownloadedTags
            lastDownloadedTags = [];
        }
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
        
        // If we typed in more than one character...
        if(substring.characters.count == 1) {
            // If lastDownloadedTags is empty...
            if(lastDownloadedTags == []) {
                // Search for any tags with the current substring as a prefix
                tokenBooru?.utilties.getTagsMatchingSearch(substring + "*", completionHandler: finishedDownloadingTags);
            }
        }
        
        // For every tag in lastDownloadedTags...
        for(_, currentDownloadedTag) in lastDownloadedTags.enumerate() {
            // If the current tag has the current substring as a prefix...
            if(currentDownloadedTag.hasPrefix(substring)) {
                // Add the current tag to the completions
                completions.append(currentDownloadedTag);
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
        
        // Remove all the duplicates from completions
        completions = Array(Set(completions));
        
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
    }
    
    override func awakeFromNib() {
        // Set the delegate
        self.delegate = self;
    }
}
