
//
//  BCExtensions.swift
//  Booru-chan
//
//  Created by Seth on 2016-05-03.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa

extension NSTokenField {
    /// All the tokens that are currently entered in the field
    var tokens : [String] {
        // Return the tokens
        if(self.tokenStyle == .None) {
            return self.stringValue.componentsSeparatedByString(" ");
        }
        else {
            return self.stringValue.componentsSeparatedByString(",");
        }
    }
    
    /// Adds the given token from this token field's tokens
    func addToken(token : String) {
        if(self.tokenStyle == .None) {
            // Add the given token to this fields tokens
            self.stringValue += " " + token;
        }
        else {
            // Add the given token to this fields tokens
            self.stringValue += "," + token;
        }
    }
    
    /// Removes the given token from this token field's tokens
    func removeToken(token : String) {
        // Replace all occurences of the given token with a blank
        self.stringValue = self.stringValue.stringByReplacingOccurrencesOfString(token, withString: "");
    }
}
