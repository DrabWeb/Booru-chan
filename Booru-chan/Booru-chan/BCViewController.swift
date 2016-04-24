//
//  BCViewController.swift
//  Booru-chan
//
//  Created by Seth on 2016-04-23.
//  Copyright © 2016 DrabWeb. All rights reserved.
//

import Cocoa

class BCViewController: NSViewController, NSWindowDelegate {
    
    /// The main window of this view controller
    var window : NSWindow = NSWindow();
    
    /// The  controller for browsing boorus in Grid|Image mode
    @IBOutlet var gridStyleController: BCGridStyleController!
    
    /// The visual effect view for the window's titlebar
    @IBOutlet var titlebarVisualEffectView: NSVisualEffectView!
    
    /// The visual effect view for the window's background
    @IBOutlet var backgroundVisualEffectView: NSVisualEffectView!
    
    /// The constraint for the toolbar items for what the minium size of the left container can be
    @IBOutlet var titlebarItemsSplitViewLeftMinimumWidthConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Style the window
        styleWindow();
        
        // Initialize everything
        gridStyleController.initialize();
    }
    
    func windowWillEnterFullScreen(notification: NSNotification) {
        // Hide the toolbar
        window.toolbar?.visible = false;
        
        // Set the window's appearance to vibrant dark so the fullscreen toolbar is dark
        window.appearance = NSAppearance(named: NSAppearanceNameVibrantDark);
        
        // Update the titlebar items split view left side minimum width
        titlebarItemsSplitViewLeftMinimumWidthConstraint.constant = 8;
    }
    
    func windowDidExitFullScreen(notification: NSNotification) {
        // Show the toolbar
        window.toolbar?.visible = true;
        
        // Set back the window's appearance
        window.appearance = NSAppearance(named: NSAppearanceNameAqua);
        
        // Update the titlebar items split view left side minimum width
        titlebarItemsSplitViewLeftMinimumWidthConstraint.constant = 78;
    }
    
    /// Styles the window
    func styleWindow() {
        // Get the window
        window = NSApplication.sharedApplication().windows.last!;
        
        // Set the window's delegate
        window.delegate = self;
        
        // Style the titlebar
        window.titlebarAppearsTransparent = true;
        window.titleVisibility = .Hidden;
        
        window.styleMask |= NSFullSizeContentViewWindowMask;
        window.toolbar?.showsBaselineSeparator = false;
        
        // Set the visual effects views' materials
        titlebarVisualEffectView.material = .Dark;
        backgroundVisualEffectView.material = .Dark;
    }
}