//
//  SuggestionTag.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-16.
//  Copyright © 2018 DrabWeb. All rights reserved.
//

import Foundation

class SuggestionTag: SuggestionItem {
    let tag: Tag;

    init(tag: Tag) {
        self.tag = tag;
        super.init(title: tag.name);
    }
}
