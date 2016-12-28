//
//  BCSBooruSearchTokenField.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-26.
//

import Cocoa
import SwiftyJSON
import Alamofire

/// The custom NSTokenField for tag search fields
class BCBooruSearchTokenField: BCAlwaysActiveTokenField, NSTokenFieldDelegate {
    
    /// The Booru to use to get the autocompletion suggestions
    var tokenBooru : BCBooruHost? = nil;
    
    /// The object to perform tokensChangedAction
    var tokensChangedTarget : AnyObject? = nil;
    
    /// The selector to call when tokens are added/removed
    var tokensChangedAction : Selector? = nil;
    
    /// The last tags that were downloaded from searching
    var lastDownloadedTags : [String] = [];
    
    /// The last search that triggered a tag download
    var lastDownloadSearch : String = "";
    
    /// Used for checking when the user has deleted a token
    var lastTokens : [String] = [];
    
    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification);
        
        // If we have more tokens than last time...
        if(self.tokens.count < lastTokens.count || self.tokens.count > lastTokens.count) {
            // If tokensChangedTarget and tokensChangedAction arent nil...
            if(tokensChangedTarget != nil && tokensChangedAction != nil) {
                // Call the tokens changed action
                _ = tokensChangedTarget!.perform(tokensChangedAction!);
            }
            
            // Empty lastDownloadedTags
            lastDownloadedTags = [];
        }
        // If it says we have one token and stringValue is empty...
        else if(self.tokens.count == lastTokens.count && self.stringValue == "") {
            // If tokensChangedTarget and tokensChangedAction arent nil...
            if(tokensChangedTarget != nil && tokensChangedAction != nil) {
                // Call the tokens changed action
                _ = tokensChangedTarget!.perform(tokensChangedAction!);
            }
            
            // Empty lastDownloadedTags
            lastDownloadedTags = [];
        }
        
        lastTokens = self.tokens;
    }
    
    func tokenField(_ tokenField: NSTokenField, readFrom pboard: NSPasteboard) -> [Any]? {
        // Return the text from pboard split at every space
        return (pboard.string(forType: NSStringPboardType)?.components(separatedBy: " "));
    }
    
    func tokenField(_ tokenField: NSTokenField, writeRepresentedObjects objects: [Any], to pboard: NSPasteboard) -> Bool {
        // Add the string type to the pasteboard
        pboard.declareTypes([NSStringPboardType], owner: nil);
        
        /// The string to paste to the pasteboard
        var pasteString : String = "";
        
        // For every string in objects...
        for(_, currentString) in (objects as! [String]).enumerated() {
            // Add the current string with a trailing space to pasteString
            pasteString += currentString + " ";
        }
        
        // If pasteString isnt empty...
        if(pasteString != "") {
            // Remove the final trailing space from pasteString
            pasteString = pasteString.substring(to: pasteString.characters.index(before: pasteString.endIndex));
        }
        
        // Paste pasteString to the pasteboard
        pboard.setString(pasteString, forType: NSStringPboardType);
        
        // Always allow copying tokens
        return true;
    }
    
    func tokenField(_ tokenField: NSTokenField, shouldAdd tokens: [Any], at index: Int) -> [Any] {
        // Empty lastDownloadedTags
        lastDownloadedTags = [];
        
        // If tokensChangedTarget and tokensChangedAction arent nil...
        if(tokensChangedTarget != nil && tokensChangedAction != nil) {
            // Call the tokens changed action
            _ = tokensChangedTarget!.perform(tokensChangedAction!);
        }
        
        // Return the given tokens	
        return tokens;
    }
    
    func tokenField(_ tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<UnsafeMutablePointer<Int>>?) -> [Any]? {
        /// The completions for this substring
        var completions : [String] = [];
        
        // Make sure the Token Booru's cache folder exists
        tokenBooru?.createCacheFolder();
        
        // If we typed in one character and its not a space or blank...
        if(substring.characters.count == 1 && substring != " " && substring != "") {
            // If lastDownloadedTags is empty...
            if(lastDownloadedTags == []) {
                // If there is already a cache file for this search...
                if(FileManager.default.fileExists(atPath: ((tokenBooru?.cacheFolderPath) ?? "") + substring + ".json")) {
                    // Load the results from that file
                    // Print that we are loading results from a cache file
                    Swift.print("BCBooruSearchTokenField: Loading search results cache from \"\(tokenBooru!.cacheFolderPath + substring + ".json")\"");
                    
                    // Asynchronously load the cached file
                    DispatchQueue.main.async {
                        /// The JSON from the results cache file
                        let resultsCacheJson : JSON = JSON(data: FileManager.default.contents(atPath: self.tokenBooru!.cacheFolderPath + substring + ".json")!);
                        
                        // Set lastDownloadedTags to the cached results
                        self.lastDownloadedTags = resultsCacheJson["results"].arrayObject as! [String];
                    }
                }
                // If there isnt a cache file for this search...
                else {
                    // Search for any tags with the current substring as a prefix
                    _ = tokenBooru?.utilties?.getTagsMatchingSearch(substring + "*", completionHandler: finishedDownloadingTags);
                }
                
                // Set lastDownloadSearch
                lastDownloadSearch = substring;
            }
        }
        
        // If tokenBooru isnt nil...
        if(tokenBooru != nil) {
            // For every tag in the Token Booru's tag search history...
            for(_, currentHistoryTag) in tokenBooru!.tagHistory.enumerated() {
                // If the current tag has the current substring as a prefix...
                if(currentHistoryTag.hasPrefix(substring)) {
                    // Add the current tag to the completions
                    completions.append(currentHistoryTag);
                }
            }
        }
        
        // For every tag in lastDownloadedTags...
        for(_, currentDownloadedTag) in lastDownloadedTags.enumerated() {
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
    func finishedDownloadingTags(_ tags : [String]) {
        // Print what tags we downloaded
        Swift.print("BCBooruSearchTokenField: Downloaded tags for completion: \(tags)");
        
        // If lastDownloadedTags is empty...
        if(lastDownloadedTags == []) {
            // Set lastDownloadedTags to the downloaded tags
            lastDownloadedTags = tags;
        }
        
        // If the tags arent empty...
        if(tags != []) {
            // Cache the tag results
            /// The JSON to hold the results
            var tagsJson : JSON = JSON(["results":[]]);
            
            // Set the results value
            tagsJson["results"].arrayObject = tags;
            
            do {
                // Print where we are saving the JSON
                Swift.print("BCBooruSearchTokenField: Writing search cache to \"\((tokenBooru?.cacheFolderPath)! + tags[0].substring(to: tags[0].characters.index(after: tags[0].startIndex)) + ".json"))\"");
                
                // POTENTIONALLY BROKEN
                // Write the JSON to a JSON file in the Token Booru's cache folder(With the name of the first character in the first item of tags)
                try String(describing: tagsJson).write(toFile: (tokenBooru?.cacheFolderPath)! + tags[0].substring(to: tags[0].index(after: tags[0].startIndex)) + ".json", atomically: true, encoding: String.Encoding.utf8);
            }
            catch let error as NSError {
                // Print the error
                Swift.print("BCBooruSearchTokenField: Failed to write JSON cache file, \(error.description)");
            }
        }
    }
    
    override func awakeFromNib() {
        // Set the delegate
        self.delegate = self;
    }
}
