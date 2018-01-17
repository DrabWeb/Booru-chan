//
//  TagType.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Cocoa

enum TagType {
    case copyright
    case character
    case artist
    case general

    func representedColour() -> NSColor {
        switch self {
            case .copyright:
                return NSColor(red: 170 / 255, green: 0, blue: 170 / 255, alpha: 1);
            case .character:
                return NSColor(red: 0, green: 170 / 255, blue: 0, alpha: 1);
            case .artist:
                return NSColor(red: 170 / 255, green: 0, blue: 0, alpha: 1);
            case .general:
                return NSColor(red: 0, green: 115 / 255, blue: 255 / 255, alpha: 1);
        }
    }
}
