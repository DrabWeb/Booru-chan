//
//  SuggestionSection.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Foundation

class SuggestionSection: SuggestionItem {
    let items: [SuggestionItem];

    init(title: String, items: [SuggestionItem]) {
        self.items = items;
        super.init(title: title);
    }
}
