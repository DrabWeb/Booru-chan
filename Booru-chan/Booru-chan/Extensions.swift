
//
//  Extensions.swift
//  Booru-chan
//
//  Created by Ushio on 2016-05-03.
//

import Cocoa

extension NSTokenField {
    /// All the tokens that are currently entered in the field
    var tokens : [String] {
        // Return the tokens
        if(self.tokenStyle == .none) {
            return self.stringValue.components(separatedBy: " ");
        }
        else {
            return self.stringValue.components(separatedBy: ",");
        }
    }

    /// Adds the given token from this token field's tokens
    func addToken(_ token : String) {
        if(self.tokenStyle == .none) {
            // Add the given token to this fields tokens
            self.stringValue += " " + token;
        }
        else {
            // Add the given token to this fields tokens
            self.stringValue += "," + token;
        }
    }
}
