//
//  BooruSearchField.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Cocoa

class BooruSearchField: NSSearchField {

    private let suggestionsWindowController = NSStoryboard(name: NSStoryboard.Name(rawValue: "SuggestionsWindow"), bundle: nil).instantiateInitialController() as! SuggestionsWindowController;

    override func becomeFirstResponder() -> Bool {
        //when the child window is ordered out it is detached from its parent, so add it back again here
        self.window!.addChildWindow(suggestionsWindowController.window!, ordered: .above);
        suggestionsWindowController.showWindow(self);

        return super.becomeFirstResponder();
    }

    override func awakeFromNib() {
        super.awakeFromNib();

        suggestionsWindowController.loadWindow();

        self.postsFrameChangedNotifications = true;
        NotificationCenter.default.addObserver(self, selector: #selector(updateSuggestionsSize), name: NSView.frameDidChangeNotification, object: nil);
    }

    override func textDidEndEditing(_ notification: Notification) {
        suggestionsWindowController.window!.orderOut(self);
        super.textDidEndEditing(notification);
    }

    @objc func updateSuggestionsSize() {
        let w = suggestionsWindowController.window!;

        let o = self.window!.frame.origin;
        let s = self.window!.frame.size;
        let h = CGFloat(139); //w.contentView?.bounds.height ?? 0
        w.setFrameOrigin(NSPoint(x: (o.x + s.width) - bounds.width - 7,
                                 y: (o.y + s.height) - h - 36));
        w.setContentSize(NSSize(width: bounds.width, height: h));
    }
}