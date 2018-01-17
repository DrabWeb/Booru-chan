//
//  SuggestionsTagCellView.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-16.
//

import Cocoa

class SuggestionsTagCellView: NSTableCellView {

    @IBOutlet private weak var hitsTextField: NSTextField!

    var representedTag: Tag! {
        didSet {
            updateAttributedString();
        }
    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            updateAttributedString();
        }
    }

    private func updateAttributedString() {

        let typeBullet = "● ";
        let title = NSMutableAttributedString(string: typeBullet + representedTag.name, attributes: [.foregroundColor: backgroundStyle == .light ? NSColor.labelColor : NSColor.white]);
        title.addAttributes([.foregroundColor: representedTag.type.representedColour()], range: NSMakeRange(0, typeBullet.count));
        hitsTextField.textColor = backgroundStyle == .light ? NSColor.secondaryLabelColor : NSColor.white;

        textField!.attributedStringValue = title;
        hitsTextField.stringValue = "10k";
    }
}
