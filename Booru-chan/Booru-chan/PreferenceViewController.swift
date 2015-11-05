//
//  PreferenceViewController.swift
//  Booru-chan
//
//  Created by Seth on 2015-11-03.
//  Copyright © 2015 DrabWeb. All rights reserved.
//

import Cocoa

class PreferenceViewController: NSViewController {

    // The visual effect view for the background of the window
    @IBOutlet weak var backgroundVisualEffectView: NSVisualEffectView!
    
    // The visual effect view for the titlebar of the window
    @IBOutlet weak var titlebarVisualEffectView: NSVisualEffectView!
    
    // The popup button that allows the user to set the theme
    @IBOutlet weak var themePopupButton: NSPopUpButton!
    
    // The text field that allows the user to edit where saved images are put
    @IBOutlet weak var savePathTextField: NSTextField!
    
    // The text field that allows the user to edit where wallpapers are saved
    @IBOutlet weak var wallpaperSavePathTextfield: NSTextField!
    
    // The UI theme (0 = Dark, 1 = Light)
    var theme : Int = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        // Load the preferences
        loadPreferences();
        
        // Wait for 0.01 seconds to style the window (If done earlier, the app crashes because it cant get the window)
        var windowTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(0.01), target:self, selector: Selector("styleWindow"), userInfo: nil, repeats:false);
    }
    
    // When the widnow is going out of sight
    override func viewWillDisappear() {
        // Save the preferences
        writePreferences();
    }
    
    func styleWindow() {
        // Get the main window
        var window : NSWindow? = titlebarVisualEffectView.window;
        
        // Style the window
        window!.titlebarAppearsTransparent = true;
        window!.titleVisibility = NSWindowTitleVisibility.Hidden;
        
        // Setup the visual effect views
        // If the theme is dark...
        if(theme == 0) {
            // Load the dark theme
            backgroundVisualEffectView.material = NSVisualEffectMaterial.Dark;
            titlebarVisualEffectView.material = NSVisualEffectMaterial.Titlebar;
            backgroundVisualEffectView.appearance = NSAppearance(named: NSAppearanceNameVibrantDark);
        }
        // If the theme is light...
        else if(theme == 1) {
            // Load the light theme
            backgroundVisualEffectView.material = NSVisualEffectMaterial.MediumLight;
            titlebarVisualEffectView.material = NSVisualEffectMaterial.Light;
            backgroundVisualEffectView.appearance = NSAppearance(named: NSAppearanceNameVibrantLight);
        }
    }
    
    // Weites the preferences to a file in application support
    func writePreferences() {
        // If the Booru-chan folder doesnt exist in the application support directory...
        if(!NSFileManager.defaultManager().fileExistsAtPath(NSHomeDirectory() + "/Library/Application Support/Booru-chan")) {
            // Try to create a folder called "Booru-chan" in application support. If there is an error, it prints it to the log
            do {
                try NSFileManager().createDirectoryAtURL(NSURL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support/Booru-chan"), withIntermediateDirectories: false, attributes: nil);
            } catch let error as NSError {
                print(error.description);
            }
        }
        
        // Get the label of the selected theme from the popup button
        var selectedThemeLabel : String = (themePopupButton.selectedItem?.title)!;
        
        // Create a variable to store the int value of the selected theme (0 = Dark, 1 = Light)
        var selectedThemeInt : Int = 0;
        
        // If the label of the selected theme is Dark...
        if(selectedThemeLabel == "Dark") {
            // Set selectedThemeInt to 0
            selectedThemeInt = 0;
        }
        // If the label of the selected theme is Light...
        else if(selectedThemeLabel == "Light") {
            // Set selectedThemeInt to 1
            selectedThemeInt = 1;
        }
        
        // Create a String with the preference files contents
        // 1 = Theme
        // 2 = Save Path
        // 3 = Wallpaper Save Path
        var preferenceFileContents : String = String(selectedThemeInt) + "\n" + savePathTextField.stringValue + "\n" + wallpaperSavePathTextfield.stringValue;
        
        // Try to write it to a file in "Booru-chan" in application support. If there is an error, it prints it to the log
        do {
            try preferenceFileContents.writeToFile(NSHomeDirectory() + "/Library/Application Support/Booru-chan/preferences", atomically: true, encoding: NSUTF8StringEncoding);
        } catch let error as NSError {
            print(error.description)
        }
    }
    
    // Loads the preferences from the preference file in application suppoirt and updates the UI to have these values
    func loadPreferences() {
        // If the preference folder exists...
        if(NSFileManager.defaultManager().fileExistsAtPath(NSHomeDirectory() + "/Library/Application Support/Booru-chan/preferences")) {
            // Continue on
            // Load the text of the preference file in Application Support
            let location = NSHomeDirectory() + "/Library/Application Support/Booru-chan/preferences";
            let fileContent = try! String(contentsOfFile: location, encoding: NSUTF8StringEncoding);
            
            // Split the file contents on every new line
            // Line 1 = Theme
            // Line 2 = Save Path
            // Line 3 = Wallpaper Save Path
            let splitPreferences : [String] = fileContent.characters.split{$0 == "\n"}.map(String.init);
            
            // Print to the log what settings we are loading
            print("Loading preferences (Theme: " + splitPreferences[0] + ", Save Path: " + splitPreferences[1] + ", Wallpaper Save Path: " + splitPreferences[2] + ")");
            
            // Set the theme popup buttons value
            themePopupButton.selectItemAtIndex(Int(splitPreferences[0])!);
            
            // Set the save path text fields value
            savePathTextField.stringValue = splitPreferences[1];
            
            // Set the wallpaper save path text fields value
            wallpaperSavePathTextfield.stringValue = splitPreferences[2];
            
            // Set the theme variables value, so we can load the theme
            theme = Int(splitPreferences[0])!;
        }
        else {
            // It doesnt exist, print this to the log
            print("Preference file doesnt exist in Application Support");
        }
    }
}
