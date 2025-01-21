# Exposé for MacOS

Step 1: Create the Swift Script  
1. Open a code editor and type the script below.  
2. Save it as `expose.swift` and run it with:  
   ```bash
   swift expose.swift
   ```

Step 2: Create an Automator Application  
1. Open Automator.  
2. Create a New Document:  
   - Select Application as the type of document.  
3. Add a “Run Shell Script” Action:  
   - In the left-hand library pane, search for “Run Shell Script.”  
   - Drag and drop the “Run Shell Script” action into the workflow pane.  
4. Enter Your Shell Script:  
   ```bash
   #!/bin/sh
   /usr/bin/swift ~/Documents/expose.swift
   ```
5. Save as an app.  
6. Move the app to the Applications folder.  
7. Open it and allow necessary permissions.  

Step 3: Update Security and Privacy Settings  
1. Go to **Settings > Security > Accessibility**:  
   - Enable `expose`.  
2. Go to **Settings > Security > Automation**:  
   - Enable `expose`.  
3. For Logi Options:  
   - Select a button to open the app: `expose.app`.  

Step 4: Export the Application  
1. Go to **File > Export**.  
2. In the Export As field, give your app a name.  
3. In the File Format dropdown menu, select **Application**.  
4. (Optional) Check the Stay Open checkbox if the app should remain running after execution.  

Step 5: Add App to Privacy Categories  
1. Go to **System Preferences > Security & Privacy > Privacy**.  
2. Add your app to relevant categories (e.g., Accessibility, Automation).  

---

AppleScript Code for Window Arrangement:  

```swift
import Cocoa
import ApplicationServices

// Get screen dimensions
let screenWidth = NSScreen.main?.frame.size.width ?? 0
let screenHeight = NSScreen.main?.frame.size.height ?? 0

// Initialize array for windows
var allWindows: [(win: NSWindow, xCoord: CGFloat, widthHeight: NSSize, appName: String)] = []

// Function to get app windows
func getAppWindows(bundleIdentifier: String) -> [AXUIElement] {
    guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
        return []
    }
    
    let appRef = AXUIElementCreateApplication(app.processIdentifier)
    
    var windowsList: CFTypeRef?
    let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsList)
    
    guard result == .success,
          let windowsArray = (windowsList as? NSArray) as? [AXUIElement] else {
        return []
    }
    
    return windowsArray
}

// Function to collect visible windows
func collectWindows() -> [(window: AXUIElement, xCoord: CGFloat, widthHeight: NSSize, appName: String)] {
    var collectedWindows: [(window: AXUIElement, xCoord: CGFloat, widthHeight: NSSize, appName: String)] = []
    
    let runningApplications = NSWorkspace.shared.runningApplications
    for app in runningApplications {
        if app.activationPolicy == .regular, let appBundle = app.bundleIdentifier {
            let appName = app.localizedName ?? "Unknown"
            let appWindows = getAppWindows(bundleIdentifier: appBundle)
            
            for window in appWindows {
                var position = CGPoint.zero
                var size = CGSize.zero
                
                // Get position
                var positionValue: AnyObject?
                AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
                if let positionValue = positionValue {
                    AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
                }
                
                // Get size
                var sizeValue: AnyObject?
                AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
                if let sizeValue = sizeValue {
                    AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
                }
                
                // Skip Finder windows at (0,0)
                if appName == "Finder" && position.x == 0 && position.y == 0 {
                    continue
                }
                
                // Prepare the window entry
                let newWindow = (window, position.x, NSSize(width: size.width, height: size.height), appName)
                
                // Insert window based on xCoord
                if let index = collectedWindows.firstIndex(where: { $0.xCoord > position.x }) {
                    collectedWindows.insert(newWindow, at: index)
                } else {
                    collectedWindows.append(newWindow)
                }
            }
        }
    }
    return collectedWindows
}

// Function to arrange windows side by side
func arrangeWindowsSideBySide() {
    // Check accessibility permissions
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)
    
    print("Accessibility enabled:", accessibilityEnabled)
    if !accessibilityEnabled {
        print("Please enable accessibility permissions in System Preferences")
        exit(1)
    }

    let windows = collectWindows()
    print("Collected windows count:", windows.count)
    
    if windows.isEmpty {
        print("No windows found")
        exit(0)
    }
    
    let windowCount = windows.count
    // Calculate target width based on window count
    let targetWidth: CGFloat
    if windowCount <= 2 {
        targetWidth = screenWidth / 3
    } else {
        targetWidth = screenWidth / CGFloat(windowCount)
    }
    let targetHeight = screenHeight
    
    // Animation parameters
    let n: Int = 10  // Number of animation steps
    
    for step in 1...n {
        for (index, windowDetails) in windows.enumerated() {
            // Get current position and size
            var currentPosition = CGPoint.zero
            var currentSize = CGSize.zero
            
            var positionValue: AnyObject?
            var sizeValue: AnyObject?
            AXUIElementCopyAttributeValue(windowDetails.window, kAXPositionAttribute as CFString, &positionValue)
            AXUIElementCopyAttributeValue(windowDetails.window, kAXSizeAttribute as CFString, &sizeValue)
            
            if let positionValue = positionValue {
                AXValueGetValue(positionValue as! AXValue, .cgPoint, &currentPosition)
            }
            if let sizeValue = sizeValue {
                AXValueGetValue(sizeValue as! AXValue, .cgSize, &currentSize)
            }
            
            // Calculate target position based on window count
            let finalX: CGFloat
            if windowCount == 1 {
                finalX = screenWidth / 3
            } else if windowCount == 2 {
                if index == 0 {
                    finalX = (screenWidth / 2) - targetWidth
                } else {
                    finalX = screenWidth / 2
                }
            } else {
                finalX = targetWidth * CGFloat(index)
            }
            let finalY = screenHeight - targetHeight
            
            // Interpolate between current and final positions/sizes
            let progress = CGFloat(step) / CGFloat(n)
            let newX = currentPosition.x + (finalX - currentPosition.x) * progress
            let newY = currentPosition.y + (finalY - currentPosition.y) * progress
            let newWidth = currentSize.width + (targetWidth - currentSize.width) * progress
            let newHeight = currentSize.height + (targetHeight - currentSize.height) * progress
            
            // Create position and size values
            let position = CGPoint(x: newX, y: newY)
            let size = CGSize(width: newWidth, height: newHeight)
            
            // Convert position and size to AXValue
            var axPosition = position
            let axPositionRef = AXValueCreate(.cgPoint, &axPosition)!
            
            var axSize = size
            let axSizeRef = AXValueCreate(.cgSize, &axSize)!
            
            // Set new position and size
            AXUIElementSetAttributeValue(windowDetails.window, kAXPositionAttribute as CFString, axPositionRef)
            AXUIElementSetAttributeValue(windowDetails.window, kAXSizeAttribute as CFString, axSizeRef)
        }
        
        // Add a small delay between steps
        Thread.sleep(forTimeInterval: 0.02)
    }
}

// Replace the CSV output with window arrangement
arrangeWindowsSideBySide()
```