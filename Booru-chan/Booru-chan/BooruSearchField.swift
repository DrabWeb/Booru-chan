//
//  BooruSearchField.swift
//  Booru-chan
//
//  Created by Ushio on 2018-01-15.
//

import Cocoa
import Alamofire

class BooruSearchField: NSSearchField {

    private let suggestionsWindowController = NSStoryboard(name: NSStoryboard.Name(rawValue: "SuggestionsWindow"), bundle: nil).instantiateInitialController() as! SuggestionsWindowController;
    private var suggestionsController: SuggestionsController {
        get {
            return (suggestionsWindowController.contentViewController as! SuggestionsController);
        }
    }

    private var booru: BooruHost!

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

    private var currentTag: String {
        return stringValue.components(separatedBy: " ").last ?? "";
    }

    override func becomeFirstResponder() -> Bool {
        updateSuggestions();
        suggestionsVisible = true;

        return super.becomeFirstResponder();
    }

    func changeSuggestionsBooru(to booru: BooruHost) {
        self.booru = booru;
        clearAndUpdateSuggestions();
    }

    override func awakeFromNib() {
        super.awakeFromNib();

        suggestionsWindowController.loadWindow();

        self.postsFrameChangedNotifications = true;
        NotificationCenter.default.addObserver(self, selector: #selector(updateSuggestionsSize), name: NSView.frameDidChangeNotification, object: nil);

        suggestionsController.favouriteTags = ["fav1", "fav2", "fav3"];
        suggestionsController.searchHistory = ["his1", "his2", "his3"];
        suggestionsController.getSuggestions = { query, completionHandler in
            return self.booru.utilties.getAutocompleteSuggestionsFromSearch(query, limit: 10, completionHandler: { tags in
                completionHandler(tags);
            });
        };

        suggestionsController.onSelectSuggestion = { suggestion in
            if suggestion != nil {
                self.showSuggestion(suggestion!);
            }
            else {
                self.clearSuggestion();
            }
        };

        NSEvent.addLocalMonitorForEvents(matching: .keyDown, handler: { event in
            switch event.keyCode {
                case 125, 126: //up arrow or down arrow
                    // dont allow the user to press up when there is no selected item
                    if self.suggestionsVisible == true && !(event.keyCode == 126 && self.suggestionsController.selectedItem == nil) {
                        self.suggestionsWindowController.window!.firstResponder!.keyDown(with: event);
                    }
                    return nil;
                default:
                    return event;
            }
        });
    }

    private var delayedTimer: Timer?
    override func textDidChange(_ notification: Notification) {
        delayedTimer?.invalidate();
        delayedTimer  = Timer.scheduledTimer(timeInterval: TimeInterval(0.25), target: self, selector: #selector(clearAndUpdateSuggestions), userInfo: nil, repeats: false);

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

    @objc private func clearAndUpdateSuggestions() {
        self.suggestionRange = nil;
        self.updateSuggestions();
    }

    private func updateSuggestions() {
        suggestionsController.showHistory = stringValue.isEmpty;
        suggestionsController.filter = currentTag;
    }

    private var suggestionRange: Range<String.Index>!

    private func showSuggestion(_ suggestion: String) {
        clearSuggestion();

        var autocompleteText = suggestion;
        if let prefixRange = suggestion.range(of: currentTag) {
            autocompleteText.removeSubrange(suggestion.startIndex..<prefixRange.upperBound);
        }

        if !autocompleteText.isEmpty {

            stringValue += autocompleteText;

            let tagRange = stringValue.range(of: currentTag, options: .backwards, range: nil, locale: nil)!;
            suggestionRange = stringValue.index(tagRange.upperBound, offsetBy: -autocompleteText.count)..<tagRange.upperBound;
            currentEditor()?.selectedRange = NSRange(suggestionRange, in: stringValue);
        }
    }

    private func clearSuggestion() {
        if suggestionRange != nil {
            stringValue.removeSubrange(suggestionRange);
            suggestionRange = nil;
        }
    }
}
