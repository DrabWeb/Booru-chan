//
//  BooruSearchField.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Cocoa

class BooruSearchField: NSSearchField {

    private let suggestionsWindowController = NSStoryboard(name: NSStoryboard.Name(rawValue: "SuggestionsWindow"), bundle: nil).instantiateInitialController() as! SuggestionsWindowController;

    private var suggestionsVisible: Bool = false {
        didSet {
            if suggestionsVisible {
                //when the child window is ordered out it is detached from its parent, so add it back again here
                self.window!.addChildWindow(suggestionsWindowController.window!, ordered: .above);
                suggestionsWindowController.showWindow(self);
            }
            else {
                suggestionsWindowController.window!.orderOut(self);
            }
        }
    }

    override func becomeFirstResponder() -> Bool {
        suggestionsVisible = true;

        return super.becomeFirstResponder();
    }

    override func awakeFromNib() {
        super.awakeFromNib();

        suggestionsWindowController.loadWindow();

        self.postsFrameChangedNotifications = true;
        NotificationCenter.default.addObserver(self, selector: #selector(updateSuggestionsSize), name: NSView.frameDidChangeNotification, object: nil);

        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event in
            switch event.keyCode {
                case 125, 126: //up arrow or down arrow
                    if self.suggestionsVisible == true {
                        self.suggestionsWindowController.window!.firstResponder!.keyDown(with: event);
                    }
                    return nil;
                default:
                    return event;
            }
        });
    }

    override func textDidChange(_ notification: Notification) {
        var items: [SuggestionItem] = [];
        for (_, c) in stringValue.enumerated() {
            items.append(SuggestionItem(title: String(c)));
        }

        (suggestionsWindowController.contentViewController as! SuggestionsController).items = [SuggestionSection(title: "Search Test", items: items)];
        super.textDidChange(notification);
    }

    override func textDidEndEditing(_ notification: Notification) {
        suggestionsVisible = false;
        super.textDidEndEditing(notification);
    }

    @objc func updateSuggestionsSize() {
        let w = suggestionsWindowController.window!;

        let o = self.window!.frame.origin;
        let s = self.window!.frame.size;
        let h = CGFloat(w.contentView?.bounds.height ?? 0);
        w.setFrameOrigin(NSPoint(x: (o.x + s.width) - bounds.width - 7,
                                 y: (o.y + s.height) - h - 36));
        w.setContentSize(NSSize(width: bounds.width, height: h));
    }
}
