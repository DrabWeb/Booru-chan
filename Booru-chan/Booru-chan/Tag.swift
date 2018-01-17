//
//  Tag.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Foundation

class Tag: Equatable {
    var name: String = "";
    var type: TagType = .general;
    var hits: Int = 0;

    static func ==(lhs: Tag, rhs: Tag) -> Bool {
        return lhs.name == rhs.name &&
               lhs.type == rhs.type &&
               lhs.hits == rhs.hits;
    }

    init(name: String = "",
         type: TagType = .general,
         hits: Int = 0) {
        self.name = name;
        self.type = type;
        self.hits = hits;
    }
}
