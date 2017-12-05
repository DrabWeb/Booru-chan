//
//  ImageUtilities.swift
//  Booru-chan
//
//  Created by Ushio on 2016-05-06.
//

import Cocoa

class ImageUtilities {
    /// Returns the NSBitmapImageFileType from the given extension
    func fileTypeFromExtension(_ fileExtension : String) -> NSBitmapImageRep.FileType? {
        /// The file type to return
        var fileType : NSBitmapImageRep.FileType? = nil;
        
        // If the extension is PNG...
        if(fileExtension.lowercased() == "png") {
            // Set fileType to PNG
            fileType = NSBitmapImageRep.FileType.png;
        }
        // If the extension is GIF...
        else if(fileExtension.lowercased() == "gif") {
            // Set fileType to GIF
            fileType = NSBitmapImageRep.FileType.gif;
        }
        // If the extension is TIFF...
        else if(fileExtension.lowercased() == "tiff") {
            // Set fileType to TIFF
            fileType = NSBitmapImageRep.FileType.tiff;
        }
        // If the extension is JPG or JPEG...
        else if(fileExtension.lowercased() == "jpg" || fileExtension.lowercased() == "jpeg") {
            // Set fileType to JPEG
            fileType = NSBitmapImageRep.FileType.jpeg;
        }
        
        // Return the file type
        return fileType;
    }
}
