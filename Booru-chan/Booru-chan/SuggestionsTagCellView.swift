//
//  SuggestionsTagCellView.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-16.
//

import Cocoa

class SuggestionsTagCellView: NSTableCellView {

    @IBOutlet private weak var postCountTextField: NSTextField!

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
        let title = NSMutableAttributedString(string: typeBullet + (representedTag.name.replacingOccurrences(of: "_", with: " ")), attributes: [.foregroundColor: backgroundStyle == .light ? NSColor.labelColor : NSColor.white]);
        title.addAttributes([.foregroundColor: representedTag.type.representedColour()], range: NSMakeRange(0, typeBullet.count));
        postCountTextField.textColor = backgroundStyle == .light ? NSColor.secondaryLabelColor : NSColor.white;

        var postCount = "\(representedTag.postCount)";
        if representedTag.postCount >= 1000 {
            postCount = "\(Int(floor(Double(representedTag.postCount / 1000))))k";
        }

        textField!.attributedStringValue = title;
        postCountTextField.stringValue = postCount;
    }
}
