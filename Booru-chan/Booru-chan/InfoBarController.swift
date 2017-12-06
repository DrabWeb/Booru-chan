//
//  InfoBarController.swift
//  Booru-chan
//
//  Created by Ushio on 2017-12-05.
//

import Cocoa

class InfoBarController: NSViewController {
    @IBOutlet private weak var label: NSTextField!

    var imageSize: NSSize! {
        didSet {
            updateLabel();
        }
    }

    var rating: Rating! {
        didSet {
            updateLabel();
        }
    }

    var loadingProgress: Float! {
        didSet {
            updateLabel();
        }
    }

    private func updateLabel() {
        if imageSize == nil && self.rating == nil && loadingProgress == nil {
            label.stringValue = "";
            return;
        }

        let size = imageSize == nil ? "?x?" : "\(Int(imageSize.width))x\(Int(imageSize.height))";
        let rating = self.rating == nil ? "?" : "\(String(String(describing: self.rating!).first!).uppercased())";
        let progress = loadingProgress == nil ? "?" : "\(Int((loadingProgress * 100).rounded()))";

        label.stringValue = "\(size) [\(rating)] \(progress)%";
    }

    override func awakeFromNib() {
        super.awakeFromNib();

        // hide the label initially
        imageSize = nil;
        rating = nil;
        loadingProgress = nil;
    }
}
