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
    func tokenField(tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>) -> [AnyObject]? {
        /// The completions for this substring
        var completions : [String] = [];
        
        // Return the completions
        return completions;
    }
    
    override func awakeFromNib() {
        // Set the delegate
        self.delegate = self;
    }
}
