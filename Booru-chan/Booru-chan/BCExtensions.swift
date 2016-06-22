
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

extension NSImage {
    /// Saves this image to the given path with the given file type
    func saveTo(filePath : String, fileType : NSBitmapImageFileType) {
        // If the bitmap representation isnt nil...
        if let imageRepresentation = self.representations[0] as? NSBitmapImageRep {
            // If the data using the given file type isnt nil...
            if let data = imageRepresentation.representationUsingType(fileType, properties: [:]) {
                // Write the data to the specified file
                data.writeToFile(filePath, atomically: false);
            }
        }
    }
}