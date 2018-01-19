//
//  SuggestionsTableView.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-18.
//  Copyright © 2018 DrabWeb. All rights reserved.
//

import Cocoa

class SuggestionsTableView: HoverSelectTableView {

    var onClick: ((Int) -> Void)?

    override func mouseDown(with event: NSEvent) {
        if selectedRow != -1 {
            onClick?(selectedRow);
        }
    }
}
