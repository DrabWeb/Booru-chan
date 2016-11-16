
//
//  BCExtensions.swift
//  Booru-chan
//
//  Created by Seth on 2016-05-03.
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
    
    /// Removes the given token from this token field's tokens
    func removeToken(_ token : String) {
        // Replace all occurences of the given token with a blank
        self.stringValue = self.stringValue.replacingOccurrences(of: token, with: "");
    }
}

extension NSImage {
    /// Saves this image to the given path with the given file type
    func saveTo(_ filePath : String, fileType : NSBitmapImageFileType) {
        // If the bitmap representation isnt nil...
        if let imageRepresentation = self.representations[0] as? NSBitmapImageRep {
            // If the data using the given file type isnt nil...
            if let data = imageRepresentation.representation(using: fileType, properties: [:]) {
                // Write the data to the specified file
                try? data.write(to: URL(fileURLWithPath: filePath), options: []);
            }
        }
    }
}

extension Int {
    static func fromBool(bool : Bool) -> Int {
        return bool ? 1 : 0;
    }
}
