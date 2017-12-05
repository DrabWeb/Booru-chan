
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
    func saveTo(_ filePath : String, fileType : NSBitmapImageRep.FileType) {
        // If the bitmap representation isnt nil...
        if let imageRepresentation = self.representations[0] as? NSBitmapImageRep {
            // If the data using the given file type isnt nil...
            if let data = imageRepresentation.representation(using: fileType, properties: [:]) {
                // Write the data to the specified file
                try? data.write(to: URL(fileURLWithPath: filePath), options: []);
            }
        }
    }
    
    /// Returns the MD5 string of the TIFF representation of this image
    func MD5() -> String? {
        let imageData = self.tiffRepresentation;
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            imageData?.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG((imageData?.count)!), digestBytes)
            }
        }
        
        return digestData.map { String(format: "%02hhx", $0) }.joined();
    }
}

extension Int {
    static func fromBool(bool : Bool) -> Int {
        return bool ? 1 : 0;
    }
}
