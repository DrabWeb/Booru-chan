//
//  WindowController.swift
//  Booru-chan
//
//  Created by Ushio on 12/28/16.
//

import Cocoa

class BooruWindowController: NSWindowController {

    private var subwindowController: BooruWindowController?
    
    @IBOutlet private weak var booruPopUpButton: NSPopUpButton!

    @IBAction override func newWindowForTab(_ sender: Any?) {
        // tabbing is only available on 10.12+
        if #available(OSX 10.12, *) {
            let windowController = storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "BrowserWindowController")) as! BooruWindowController;

            window?.addTabbedWindow(windowController.window!, ordered: .above);
            subwindowController = windowController;
            windowController.window?.orderFront(window);
            windowController.window?.makeKey();
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad();

        window!.titleVisibility = .hidden;
        NotificationCenter.default.addObserver(self, selector: #selector(updateBooruPopUpButton), name: NSNotification.Name(rawValue: "Preferences.Updated"), object: nil);
        updateBooruPopUpButton();
    }

    @objc func updateBooruPopUpButton() {
        let boorus = (NSApp.delegate as! AppDelegate).preferences.booruHosts;
        var selection = booruPopUpButton.indexOfSelectedItem;

        booruPopUpButton.removeAllItems();
        for (_, b) in boorus.enumerated() {
            booruPopUpButton.addItem(withTitle: b.name);
        }

        if selection < 0 {
            selection = 0;
        }
        else if selection > booruPopUpButton.numberOfItems - 1 {
            selection = booruPopUpButton.numberOfItems - 1;
        }

        booruPopUpButton.selectItem(at: selection);

        // no proper way to force trigger an nscontrols action
        (contentViewController as! BooruController).booruChanged(booruPopUpButton);
    }
}
