//
//  BooruType.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-14.
//

import Foundation

/// The different types of Booru Booru-chan can use
enum BooruType: Int {
    /// Used for placeholders/variable initiation
    case unchosen

    /// Moebooru
    case moebooru

    /// Danbooru 1.x
    case danbooruLegacy

    /// Danbooru 2.x
    case danbooru

    /// Gelbooru
    case gelbooru
}
