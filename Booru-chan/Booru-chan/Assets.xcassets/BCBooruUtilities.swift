//
//  BCBooruUtilities.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa

class BCBooruUtilities {
    /// The type of Booru to use for this Booru Utilities
    var type : BCBooruType = .Unchosen;
}

/// The different types of Booru Booru-chan can use
enum BCBooruType {
    /// Used for placeholders/variable initiation
    case Unchosen
    
    /// Moebooru
    case Moebooru
    
    /// Danbooru 1.x
    case DanbooruLegacy
    
    /// Danbooru 2.x
    case Danbooru
    
    /// Gelbooru
    case Gelbooru
}