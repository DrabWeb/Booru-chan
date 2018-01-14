//
//  Theme.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-14.
//

import Cocoa

enum Theme: Int {
    case none = -1, dark = 0, light = 1

    var appearance: NSAppearance? {
        get {
            switch self {
            case .dark:
                return NSAppearance(named: .vibrantDark);
            case .light:
                return NSAppearance(named: .vibrantLight);
            default:
                return nil;
            }
        }
    }
}
