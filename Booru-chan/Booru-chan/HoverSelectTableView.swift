//
//  HoverSelectTableView.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Cocoa

class HoverSelectTableView: NSTableView {

    private var trackingArea: NSTrackingArea!
    private var lastSelected: Int = -1;

    override func mouseMoved(with event: NSEvent) {
        let r = row(at: convert(event.locationInWindow, to: nil));
        if r != lastSelected {
            lastSelected = r;
            if r > -1 {
                self.selectRowIndexes(delegate?.tableView?(self, selectionIndexesForProposedSelection: [r]) ?? [], byExtendingSelection: false);
            }
            else {
                clearSelection();
            }
        }
    }

    override func mouseExited(with event: NSEvent) {
        clearSelection();
    }

    override func awakeFromNib() {
        super.awakeFromNib();

        trackingArea = NSTrackingArea(rect: self.frame, options: [.activeInActiveApp, .mouseMoved, .mouseEnteredAndExited, .inVisibleRect], owner: self, userInfo: nil);
        addTrackingArea(trackingArea);
    }

    private func clearSelection() {
        self.selectRowIndexes([], byExtendingSelection: false);
    }

    deinit {
        removeTrackingArea(trackingArea);
    }
}
