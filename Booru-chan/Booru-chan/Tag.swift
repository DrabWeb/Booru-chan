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
    var postCount: Int = 0;

    static func ==(lhs: Tag, rhs: Tag) -> Bool {
        return lhs.name == rhs.name &&
               lhs.type == rhs.type &&
               lhs.postCount == rhs.postCount;
    }

    init(name: String = "",
         type: TagType = .general,
         postCount: Int = 0) {
        self.name = name;
        self.type = type;
        self.postCount = postCount;
    }
}
