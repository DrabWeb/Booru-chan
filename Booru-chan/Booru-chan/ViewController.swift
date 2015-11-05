//
//  ViewController.swift
//  Booru-chan
//
//  Created by Seth on 2015-11-01.
//  Copyright © 2015 DrabWeb. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTableViewDataSource, NSXMLParserDelegate {
    
    // The visual effect view for the background of the window
    @IBOutlet weak var backgroundVisualEffectView: NSVisualEffectView!
    
    // The visual effect view for the titlebar of the window
    @IBOutlet weak var titlebarVisualEffectView: NSVisualEffectView!
    
    // The view on the right that shows the image in full size
    @IBOutlet weak var selectedImageLargeView: NSImageView!
    
    // The table view for the sidebar
    @IBOutlet weak var sidebarTableView: NSTableView!
    
    // The scroll view on the sidebar that wraps around the table view
    @IBOutlet weak var sidebarScrollView: NSScrollView!
    
    // The search field in the titlebar, used for searching tags
    @IBOutlet weak var tagSearchField: NSTextField!
    
    // When we hit enter in the Search Field...
    @IBAction func tagSearchFieldEntered(sender: AnyObject) {
        // Load the search results
        print("Loading search reults... (Tags: " + tagSearchField.stringValue + ", Post Limit: " + String(postLimit) + ")");
        loadSearchResults();
    }
    
    // A reference to the page stepper for changing pages
    @IBOutlet weak var pageStepper: NSStepper!
    
    // The label for what [age we are on
    @IBOutlet weak var pageStepperLabel: NSTextField!
    
    // When we press on the page stepper...
    @IBAction func pageStepperInteracted(sender: AnyObject) {
        // Set the page to the page steppers value
        currentPage = pageStepper.integerValue;
        
        // Set the page label to the new page we are on
        pageStepperLabel.stringValue = ("Page: " + String(currentPage));
        
        // Reload the results
        loadSearchResults();
    }
    
    // The current page we are on
    var currentPage : Int = 1;

    // A reference to the save menu item
    @IBOutlet var saveMenuItem: NSMenuItem!
    
    // A reference to the set as wallpaper menu item
    @IBOutlet var setWallpaperMenuItem: NSMenuItem!
    
    // When we interact with the save menu item...
    @IBAction func saveMenuItemInteracted(sender: AnyObject) {
        // Save the current image to imageSavePath
        saveCurrentImage(imageSavePath);
    }
    
    // When we interact with the set as wallpaper menu item...
    @IBAction func setWallpaperMenuItemInteracted(sender: AnyObject) {
        // Save the current image to the desktop and set the wallpaper to it
        setCurrentImageAsWallpaper(wallpaperSavePath);
    }
    
    // An array of SidebarDocs that are used to display images in the sidebar
    var sidebarItems = [SidebarDoc]();
    
    // The XML file that we will load from the Booru
    var xmlData : NSMutableData = NSMutableData();
    
    // The parser for xmlData
    var xmlParser : NSXMLParser = NSXMLParser();
    
    // A list of all the image urls for the previews of the search
    var imagePreviewUrlArray : [String] = [String]();
    
    // A list of all the image urls for the search
    var imageUrlArray : [String] = [String]();
    
    // A list of all the NSImages for the search
    var imageArray : [NSImage] = [NSImage]();
    
    // A list of all the NSImages for the previews of the search
    var imagePreviewArray : [NSImage] = [NSImage]();
    
    // How many posts to load (Min 1, Max 100)
    var postLimit : Int = 10;
    
    // The current image we have selected
    var currentImage : NSImage = NSImage();
    
    // The current image we have selected's URL
    var currentImageURL : NSURL = NSURL();
    
    // Where we save images that we download
    var imageSavePath : String = "";
    
    // Where we save images that we set as the wallpaper
    var wallpaperSavePath : String = "";
    
    // The UI theme (0 = Dark, 1 = Light)
    var theme : Int = 0;
    
    override func viewDidLoad() {
        super.viewDidLoad();

        // Do any additional setup after loading the view.
        
        // Resize the sidebarItems array to 10. For some reason when you change the item count in the table view it flips out and doesnt draw it properly.
        var blankItem : SidebarDoc = SidebarDoc(thumbnailImage: NSImage(named: "Blank")!);
        sidebarItems = [blankItem, blankItem, blankItem, blankItem, blankItem, blankItem, blankItem, blankItem, blankItem, blankItem];
        
        // Hide the sidebar
        sidebarScrollView.hidden = true;
        
        // Init the imageArray array
        sidebarTableView.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false);
        resetFullImageArray();
        
        // Sdd the save and set wallpaper menu items to the menubar (It took too long to figure out how to do this)
        NSApp.windowsMenu?.addItem(saveMenuItem);
        NSApp.windowsMenu?.addItem(setWallpaperMenuItem);
        
        // Wait for 0.01 seconds to style the window (If done earlier, the app crashes because it cant get the window)
        var windowTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(0.01), target:self, selector: Selector("styleWindow"), userInfo: nil, repeats:false);
        
        // Load the preferences
        var preferenceLoadTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(0.01), target:self, selector: Selector("loadPreferences"), userInfo: nil, repeats:false);
        
        // Do the preference loading loop
        var preferenceLoadLoopTimer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(1), target:self, selector: Selector("loadPreferences"), userInfo: nil, repeats:true);
    }
    
    func styleWindow() {
        // Get the main window
        var window : NSWindow? = self.view.window;
        
        // Style the window
        window!.titlebarAppearsTransparent = true;
        window!.styleMask |= NSUnifiedTitleAndToolbarWindowMask;
        window!.titleVisibility = NSWindowTitleVisibility.Hidden;
        
        // Setup the visual effect views
        // If the theme is dark...
        if(theme == 0) {
            // Load the dark theme
            backgroundVisualEffectView.material = NSVisualEffectMaterial.Dark;
            titlebarVisualEffectView.material = NSVisualEffectMaterial.Titlebar;
            backgroundVisualEffectView.appearance = NSAppearance(named: NSAppearanceNameVibrantDark);
            titlebarVisualEffectView.appearance = NSAppearance(named: NSAppearanceNameVibrantDark);
        }
            // If the theme is light...
        else if(theme == 1) {
            // Load the light theme
            backgroundVisualEffectView.material = NSVisualEffectMaterial.MediumLight;
            titlebarVisualEffectView.material = NSVisualEffectMaterial.Light;
            backgroundVisualEffectView.appearance = NSAppearance(named: NSAppearanceNameVibrantLight);
            titlebarVisualEffectView.appearance = NSAppearance(named: NSAppearanceNameVibrantLight);
        }
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    // Loads everything to do with the search
    func loadSearchResults() {
        // Reset the list of image URLs and images
        imageUrlArray.removeAll();
        resetFullImageArray();
        imagePreviewUrlArray.removeAll();
        imagePreviewArray.removeAll();
        
        // Create a URL to the selected Booru (Konachan) with our query
        let xmlUrl : NSURL = NSURL(string: "https://konachan.net/post.xml?limit=" + String(postLimit) + "&tags=" + tagSearchField.stringValue + "&page=" + String(currentPage))!;
        
        // Create a URL request to xmlUrl
        let urlRequest : NSMutableURLRequest = NSMutableURLRequest(URL: xmlUrl);
        
        // Create an auto loading URL connection with urlRequest
        let urlConnection : NSURLConnection = NSURLConnection(request:urlRequest, delegate: self, startImmediately: true)!;
    }
    
    // Converts all the image URLs in imagePreviewUrlArray to NSImages, and stores them in imagePreviewArray
    func convertPreviewImageUrlsToNSImage() {
        // Iterate through each element in every tag from the xml
        for(index, element) in imagePreviewUrlArray.enumerate() {
            // Load the URL into the appropriate slot in imageArray
            imagePreviewArray.append(NSImage(contentsOfURL: NSURL(string: element)!)!);
            
            // Print to the log that we loaded it
            print("Loaded preview image from " + element);
        }
        
        // Copy all the images that we have loaded over to teh sidebarItems array so we can see them in the sidebar
        createSidebarArrayFromImages();
        
        // Load the first image, just to show something
        selectImageAtIndex(0);
    }
    
    // Downloads the Image at the URL in imageUrlArray at the specified index, then load it into that same index in imageArray
    func downloadFullImageAtIndex(index : Int) {
        // Load the NSImage in the specified index, and put it in imageArray
        imageArray[index] = NSImage(contentsOfURL: NSURL(string: imageUrlArray[index])!)!;
        
        // Print to the log that it was downloaded
        print("Loaded image from " + imageUrlArray[index]);
    }
    
    // Copys all the images in imageArray to the sidebarItems array
    func createSidebarArrayFromImages() {
        // Clear out the sidebarItems array
        sidebarItems.removeAll();
        
        // Iterate through each element in the imageArray array
        for(index, element) in imagePreviewArray.enumerate() {
            // Create a new SidebarDoc with the image we are currently on
            var sidebarDoc : SidebarDoc = SidebarDoc(thumbnailImage: element);
            
            // Add it to the sidebarItems array
            sidebarItems.append(sidebarDoc);
        }
        
        // Show the sidebar
        sidebarScrollView.hidden = false;
        
        // Enable the stepper
        pageStepper.enabled = true;
    }
    
    // Resets imageArray
    func resetFullImageArray() {
        // Print to the log that we are doing this
        print("Resetting imageArray");
        
        // Create an NSImage variable with a blank image
        var image : NSImage = NSImage(named: "Blank")!;
        
        // Set imageArray to blank ten times
        imageArray = [image, image, image, image, image, image, image, image, image, image];
    }
    
    // Saves the currently selected image to the path that is passed to savePath
    func saveCurrentImage(savePath : String) {
        // Create imageName with the full image URL
        var imageName : String = currentImageURL.absoluteString;
        
        // Split imageName at every /, and set it to the last one in the array of splits
        imageName = imageName.componentsSeparatedByString("/")[imageName.componentsSeparatedByString("/").count - 1];
        
        // Replace all the %20s with spaces
        imageName = imageName.stringByReplacingOccurrencesOfString("%20", withString: " ");
        
        // Print to the log where we are saving the image and what its name will be
        print("Saving image '" + (imageName as String) + "' to " + savePath);
        
        // Create NSData with the data of the current image
        var imageData : NSData = NSData(contentsOfURL: currentImageURL)!;
        
        // Write the data to a file at savePath with imageName as its name and extension
        imageData.writeToFile(savePath + imageName, atomically: false);
    }
    
    // Sets the currently selected image as the wallpaper, and saves it to the path passed to savePath
    func setCurrentImageAsWallpaper(savePath : String) {
        // Get the name so we can reference it to set the wallpaper
        // Create imageName with the full image URL
        var imageName : String = currentImageURL.absoluteString;
        
        // Split imageName at every /, and set it to the last one in the array of splits
        imageName = imageName.componentsSeparatedByString("/")[imageName.componentsSeparatedByString("/").count - 1];
        
        // Replace all the %20s with spaces
        imageName = imageName.stringByReplacingOccurrencesOfString("%20", withString: " ");
        
        // Save the image using the function we already made
        saveCurrentImage(savePath);
        
        // Print to the log that we are setting the wallpaper
        print("Setting wallpaper to " + String(currentImageURL));
        
        // Create a new task to handle the osascript to set the wallpaper
        let wallpaperTask = NSTask();
        
        // Set the task launch path to osascript
        wallpaperTask.launchPath = "/usr/bin/osascript";
        
        // Add the arguments
        wallpaperTask.arguments = ["-e","tell application \"System Events\" to tell current desktop to set picture to \"" + savePath + imageName + "\""];
        
        // Launch it
        wallpaperTask.launch();
    }
    
    // Selects the image by showing it in the large view, and sets current image
    func selectImageAtIndex(index : Int) {
        // Check to see if the index is out of range...
        if(index >= imageArray.count) {
            print("Given index (" + String(index) + ") is out of imageArray's range (" + String(imageArray.count) + ")");
        }
        else {
            // If the image is a blank placeholder...
            if(imageArray[index] == NSImage(named: "Blank")) {
                // Download the actual image
                downloadFullImageAtIndex(index);
            }
            
            // Set current image
            currentImage = imageArray[index];
            
            // Set current image URL
            currentImageURL = NSURL(string: imageUrlArray[index])!;
            
            // Set the large image view's image
            selectedImageLargeView.image = currentImage;
            
            // Print to the log that we set the image
            print("Image at index " + String(index) + " from imageArray loaded");
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
            
            // Set the theme variables value, so we can load the theme
            theme = Int(splitPreferences[0])!;
            
            // Set the save path and wallpaper save path
            imageSavePath = splitPreferences[1];
            wallpaperSavePath = splitPreferences[2];
            
            // Re-theme the window
            styleWindow();
        }
        else {
            // It doesnt exist, print this to the log
            print("Preference file doesnt exist in Application Support");
        }
    }
    
    // Handle URL connection events
    func connection(didReceiveResponse: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        // Recieved a new request, clear out the data object
        xmlData = NSMutableData()
    }
    
    func connection(connection: NSURLConnection!, didReceiveData conData: NSData!) {
        // Append the recieved chunk of data to our data object
        xmlData.appendData(conData)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        // Request complete, self.data should now hold the resulting info
        // NSString(data: xmlData, encoding: NSUTF8StringEncoding) as! String;
        xmlParser = NSXMLParser(data: xmlData);
        xmlParser.delegate = self;
        xmlParser.parse();
    }
    // End handle URL connection events
    
    // Handle XML parser events
    // When the parser does a tag...
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        // Iterate through each element in every tag from the xml
        for(index, element) in attributeDict.enumerate() {
            // If the the element is a preview url...
            if(element.0 == "preview_url") {
                // Add the URL to the array of preview files
                imagePreviewUrlArray.append(element.1);
                
                // Reload the sidebar so it displays the images
                sidebarTableView.reloadData();
            }
            // If the the element is a file url...
            if(element.0 == "file_url") {
                // Add the URL to the array of files
                imageUrlArray.append(element.1);
            }
        }
    }
    
    // When it is done parsing the XML...
    func parserDidEndDocument(parser: NSXMLParser) {
        // Convert all the image URLs to NSImages
        convertPreviewImageUrlsToNSImage();
    }
    
    // When there is an error while parsing the XML...
    func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
        // We encountered an error, print it to the log
        print("Ecountered error: ");
        print(parseError);
    }
    // End handle XML parser events

    // Handle table view events
    // When it asks how many rows we have...
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        // Return the amount of items in the sidebar item array
        return sidebarItems.count;
    }
    
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true;
    }
    
    // When it asks for how many colums are in the table view... (This should never be called, as we only have one column)
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        // Return the value in sidebar items at the specified row
        // Return the first item in the array
//        return sidebarItems[row].thumbnailImage;
        // If the row it is looking for is outside of the array range...
        if(sidebarItems.count - 1 < row) {
            // Return a warning sign
            return NSImage(named: "NSCaution");
        }
        else {
            // Return the item at the specified row
            return sidebarItems[row].thumbnailImage;
        }
    }
    
    // When it asks for a view in teh table view at a specific row
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // Get the table view
        var cellView: NSTableCellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: self) as! NSTableCellView;
        
        // Is the table view we recieved is the Sidebar table view...
        if tableColumn!.identifier == "SidebarColumn" {
            // Create a variable to store the sidebar item at the specified row
            let sidebarDoc = self.sidebarItems[row];
            
            // Set the cell views image to be the rows sidebarDocs thumbnail image
            cellView.imageView!.image = sidebarDoc.thumbnailImage;
            
            // Return our new cell view
            return cellView;
        }
        
        // Return the cell view, nothing to see here
        return cellView;
    }
    // End handle table view events
}

