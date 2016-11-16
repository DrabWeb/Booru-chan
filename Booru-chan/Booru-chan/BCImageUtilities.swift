//
//  BCImageUtilities.swift
//  Booru-chan
//
//  Created by Seth on 2016-05-06.
//

import Cocoa

class BCImageUtilities {
    /// Returns the NSBitmapImageFileType from the given extension
    func fileTypeFromExtension(_ fileExtension : String) -> NSBitmapImageFileType? {
        /// The file type to return
        var fileType : NSBitmapImageFileType? = nil;
        
        // If the extension is PNG...
        if(fileExtension.lowercased() == "png") {
            // Set fileType to PNG
            fileType = NSBitmapImageFileType.PNG;
        }
            // If the extension is GIF...
        else if(fileExtension.lowercased() == "gif") {
            // Set fileType to GIF
            fileType = NSBitmapImageFileType.GIF;
        }
            // If the extension is TIFF...
        else if(fileExtension.lowercased() == "tiff") {
            // Set fileType to GIF
            fileType = NSBitmapImageFileType.GIF;
        }
            // If the extension is JPG or JPEG...
        else if(fileExtension.lowercased() == "jpg" || fileExtension.lowercased() == "jpeg") {
            // Set fileType to GIF
            fileType = NSBitmapImageFileType.JPEG;
        }
        
        // Return the file type
        return fileType;
    }
}
