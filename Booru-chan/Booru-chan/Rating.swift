//
//  Rating.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-14.
//

import Foundation

/// The different ratings a post can have
enum Rating: Int {
    /// Safe
    case safe

    /// Questionable(Red face)
    case questionable

    /// Explicit(L-lewd...)
    case explicit
}
