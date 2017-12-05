//
//  WindowController.swift
//  Booru-chan
//
//  Created by Ushio on 12/28/16.
//

import Cocoa

/// The window controller for booru browsers
class BooruWindowController: NSWindowController {
    
    /// The sub-BCWindowController of this `BCWindowController`(if any, used for tabbing)
    var subwindowController : BooruWindowController?
    
    @IBAction override func newWindowForTab(_ sender: Any?) {
        // Tabbing is only on 10.12+
        if #available(OSX 10.12, *) {
            /// The new `BCWindowController`
            let windowController : BooruWindowController = self.storyboard!.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(rawValue: "BrowserWindowController")) as! BooruWindowController;
            
            // Add `windowController` as a tab to this window controller
            self.window?.addTabbedWindow(windowController.window!, ordered: .above);
            
            // Set `subwindowController` to `windowController`
            self.subwindowController = windowController;
            
            // Order the tab front
            windowController.window?.orderFront(self.window);
            
            // Make the tab key
            windowController.window?.makeKey();
        }
    }

    override func windowDidLoad() {
        super.windowDidLoad();

        window!.titleVisibility = .hidden;
    }
}
