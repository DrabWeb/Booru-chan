//
//  TagListTableViewData.swift
//  Booru-chan
//
//  Created by Seth on 2016-05-03.
//

import Cocoa

class TagListTableViewData: NSObject {
    /// The name of this tag
    var tagName : String = "TagListTableViewData.Error: No tag name given";
    
    /// Does the user already have this tag in their current search tags?
    var tagBeingSearchedBy : Bool = false;
    
    // Init with a tag name and if this tag is being searched by
    init(tagName : String, tagBeingSearchedBy : Bool) {
        super.init();
        
        self.tagName = tagName;
        self.tagBeingSearchedBy = tagBeingSearchedBy;
    }
    
    // Blank init
    override init() {
        super.init();
        
        self.tagName = "TagListTableViewData: No tag name given";
        self.tagBeingSearchedBy = false;
    }
}
