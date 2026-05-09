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

Step 6: Map your exported Application to a mouse button
1. Open **Logi Options** (if your mouse is Logitech)
2. Select your mouse.
3. Under "Buttons", click the button you want to use.
4. Under "Actions" > "Other Actions" > "Open application" > Select your exported Application.

Enjoy!
---

AppleScript Code for Window Arrangement:  

```swift
// How to run: /usr/bin/swift ~/Documents/expose.swift

import Cocoa
import ApplicationServices

let alternateCenterWindowSize = false
let isLargerCenterPreferred = true // useful when alternateCenterWindowSize is FALSE

struct WindowEntry {
    let appName: String
    let bundleId: String
    let windowTitle: String
    let originalX: CGFloat
    let originalY: CGFloat
    let originalWidth: CGFloat
    let originalHeight: CGFloat
}

struct IgnoredWindowEntry {
    let appName: String
    let bundleId: String
    let windowTitle: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
    let reason: String
}

struct ScreenResult {
    let screenIndex: Int
    let screenWidth: CGFloat
    let screenHeight: CGFloat
    var positioned: [WindowEntry] = []
    var ignored: [IgnoredWindowEntry] = []
}

// Function to get app windows using Accessibility API
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

func getWindowTitle(_ window: AXUIElement) -> String {
    var titleValue: AnyObject?
    AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleValue)
    return (titleValue as? String) ?? ""
}

// Returns all visible windows with their current position/size, plus ignored ones
func collectAllWindows() -> (
    visible: [(window: AXUIElement, position: CGPoint, size: CGSize, appName: String, bundleId: String)],
    ignored: [IgnoredWindowEntry]
) {
    var collectedWindows: [(window: AXUIElement, position: CGPoint, size: CGSize, appName: String, bundleId: String)] = []
    var ignoredWindows: [IgnoredWindowEntry] = []

    let runningApplications = NSWorkspace.shared.runningApplications
    for app in runningApplications {
        if app.activationPolicy == .regular, let appBundle = app.bundleIdentifier {
            let appName = app.localizedName ?? "Unknown"
            let appWindows = getAppWindows(bundleIdentifier: appBundle)

            for window in appWindows {
                var position = CGPoint.zero
                var size = CGSize.zero

                var positionValue: AnyObject?
                AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
                if let positionValue = positionValue {
                    AXValueGetValue(positionValue as! AXValue, .cgPoint, &position)
                }

                var sizeValue: AnyObject?
                AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
                if let sizeValue = sizeValue {
                    AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
                }

                var minimizedValue: AnyObject?
                AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minimizedValue)
                let isMinimized = (minimizedValue as? NSNumber)?.boolValue ?? false

                let title = getWindowTitle(window)

                if appName == "Finder" && position.x == 0 && position.y == 0 {
                    ignoredWindows.append(IgnoredWindowEntry(appName: appName, bundleId: appBundle, windowTitle: title, x: position.x, y: position.y, width: size.width, height: size.height, reason: "Finder desktop window"))
                    continue
                }
                if isMinimized {
                    ignoredWindows.append(IgnoredWindowEntry(appName: appName, bundleId: appBundle, windowTitle: title, x: position.x, y: position.y, width: size.width, height: size.height, reason: "minimized"))
                    continue
                }
                if appName == "Defguard" {
                    ignoredWindows.append(IgnoredWindowEntry(appName: appName, bundleId: appBundle, windowTitle: title, x: position.x, y: position.y, width: size.width, height: size.height, reason: "app excluded"))
                    continue
                }

                collectedWindows.append((window, position, size, appName, appBundle))
            }
        }
    }
    return (collectedWindows, ignoredWindows)
}

// NSScreen uses flipped Y relative to Quartz/AX — convert screen frame to AX coordinate space
func axFrame(for screen: NSScreen) -> CGRect {
    let totalHeight = NSScreen.screens.reduce(CGFloat(0)) { max($0, $1.frame.maxY) }
    let frame = screen.frame
    let axY = totalHeight - frame.maxY
    return CGRect(x: frame.origin.x, y: axY, width: frame.width, height: frame.height)
}

// Arrange windows that belong to a single screen; returns a ScreenResult for JSON logging
func arrangeWindowsOnScreen(
    screenIndex: Int,
    screen: NSScreen,
    allWindows: [(window: AXUIElement, position: CGPoint, size: CGSize, appName: String, bundleId: String)],
    globalIgnored: [IgnoredWindowEntry]
) -> ScreenResult {
    let screenFrame = axFrame(for: screen)
    let screenWidth = screenFrame.width
    let screenHeight = screenFrame.height
    let screenOriginX = screenFrame.origin.x
    let screenOriginY = screenFrame.origin.y

    var result = ScreenResult(screenIndex: screenIndex, screenWidth: screenWidth, screenHeight: screenHeight)

    // Windows not on this screen go into ignored (only add global ignored on screen 1 to avoid duplication)
    if screenIndex == 1 {
        result.ignored.append(contentsOf: globalIgnored)
    }

    // Filter windows whose center falls within this screen's AX frame
    let onScreen = allWindows.filter { w in
        let center = CGPoint(x: w.position.x + w.size.width / 2, y: w.position.y + w.size.height / 2)
        return screenFrame.contains(center)
    }

    // Windows that exist but belong to a different screen — mark ignored on this screen
    let offScreen = allWindows.filter { w in
        let center = CGPoint(x: w.position.x + w.size.width / 2, y: w.position.y + w.size.height / 2)
        return !screenFrame.contains(center)
    }
    for w in offScreen {
        result.ignored.append(IgnoredWindowEntry(appName: w.appName, bundleId: w.bundleId, windowTitle: getWindowTitle(w.window), x: w.position.x, y: w.position.y, width: w.size.width, height: w.size.height, reason: "on different display"))
    }

    let windows = onScreen.sorted { $0.position.x < $1.position.x }
    let windowCount = windows.count

    guard windowCount > 0 else {
        print("  No windows on this screen.")
        return result
    }
    print("  \(windowCount) window(s): \(windows.map { $0.appName }.joined(separator: ", "))")

    let centerWindowInitialWidth = windows[Int(floor(Double(windowCount) / 2))].size.width

    let targetWidth: CGFloat
    if (windowCount == 4 || windowCount == 5) &&
       (alternateCenterWindowSize ? abs(centerWindowInitialWidth - screenWidth / CGFloat(windowCount)) < 1.0 : isLargerCenterPreferred) {
        targetWidth = screenWidth / 6
    } else if windowCount == 3 &&
       (alternateCenterWindowSize ? abs(centerWindowInitialWidth - screenWidth / CGFloat(windowCount)) < 1.0 : isLargerCenterPreferred) {
        targetWidth = screenWidth / 4
    } else if windowCount <= 2 {
        targetWidth = screenWidth / 3
    } else {
        targetWidth = screenWidth / CGFloat(windowCount)
    }
    let targetHeight = screenHeight

    for (index, windowDetails) in windows.enumerated() {
        let finalLocalX: CGFloat
        let finalWidth: CGFloat

        if windowCount == 5 && (alternateCenterWindowSize ? centerWindowInitialWidth == (screenWidth / CGFloat(windowCount)) : isLargerCenterPreferred) {
            if index < 2 {
                finalLocalX = targetWidth * CGFloat(index)
                finalWidth = targetWidth
            } else if index == 2 {
                finalLocalX = targetWidth * CGFloat(index)
                finalWidth = targetWidth * 2
            } else {
                finalLocalX = targetWidth * CGFloat(index + 1)
                finalWidth = targetWidth
            }
        } else if windowCount == 4 && (alternateCenterWindowSize ? centerWindowInitialWidth == (screenWidth / CGFloat(windowCount)) : isLargerCenterPreferred) {
            if index == 0 {
                finalLocalX = targetWidth * 0
                finalWidth = targetWidth
            } else if index == 1 {
                finalLocalX = targetWidth * 1
                finalWidth = targetWidth * 2
            } else if index == 2 {
                finalLocalX = targetWidth * 3
                finalWidth = targetWidth * 2
            } else {
                finalLocalX = targetWidth * 5
                finalWidth = targetWidth
            }
        } else if windowCount == 3 && (alternateCenterWindowSize ? abs(centerWindowInitialWidth - (screenWidth / CGFloat(windowCount))) < 1.0 : isLargerCenterPreferred) {
            if index == 0 {
                finalLocalX = targetWidth * 0
                finalWidth = targetWidth
            } else if index == 1 {
                finalLocalX = targetWidth * CGFloat(index)
                finalWidth = targetWidth * 2
            } else {
                finalLocalX = targetWidth * 3
                finalWidth = targetWidth
            }
        } else {
            if screenWidth < 5120 {
                let equalWidth = screenWidth / CGFloat(windowCount)
                finalLocalX = equalWidth * CGFloat(index)
                finalWidth = equalWidth
            } else if windowCount == 1 {
                finalLocalX = screenWidth / 3
                finalWidth = targetWidth
            } else if windowCount == 2 {
                if index == 0 {
                    finalLocalX = (screenWidth / 2) - targetWidth
                } else {
                    finalLocalX = screenWidth / 2
                }
                finalWidth = targetWidth
            } else {
                finalLocalX = targetWidth * CGFloat(index)
                finalWidth = targetWidth
            }
        }

        let finalX = screenOriginX + finalLocalX
        let finalY = screenOriginY

        let position = CGPoint(x: finalX, y: finalY)
        let size = CGSize(width: finalWidth, height: targetHeight)

        var axPosition = position
        guard let axPositionRef = AXValueCreate(.cgPoint, &axPosition) else { continue }

        var axSize = size
        guard let axSizeRef = AXValueCreate(.cgSize, &axSize) else { continue }

        AXUIElementSetAttributeValue(windowDetails.window, kAXPositionAttribute as CFString, axPositionRef)
        AXUIElementSetAttributeValue(windowDetails.window, kAXSizeAttribute as CFString, axSizeRef)

        result.positioned.append(WindowEntry(
            appName: windowDetails.appName,
            bundleId: windowDetails.bundleId,
            windowTitle: getWindowTitle(windowDetails.window),
            originalX: windowDetails.position.x,
            originalY: windowDetails.position.y,
            originalWidth: windowDetails.size.width,
            originalHeight: windowDetails.size.height
        ))
    }

    return result
}

func writeWindowListJSON(screenResults: [ScreenResult]) {
    var root: [String: Any] = [:]
    root["timestamp"] = ISO8601DateFormatter().string(from: Date())

    for result in screenResults {
        let key = "monitor\(result.screenIndex)"

        let positioned: [[String: Any]] = result.positioned.map { w in
            [
                "appName": w.appName,
                "bundleId": w.bundleId,
                "windowTitle": w.windowTitle,
                "originalPosition": ["x": w.originalX, "y": w.originalY],
                "originalSize": ["width": w.originalWidth, "height": w.originalHeight]
            ]
        }

        let ignored: [[String: Any]] = result.ignored.map { w in
            [
                "appName": w.appName,
                "bundleId": w.bundleId,
                "windowTitle": w.windowTitle,
                "position": ["x": w.x, "y": w.y],
                "size": ["width": w.width, "height": w.height],
                "reason": w.reason
            ]
        }

        root[key] = [
            "displaySize": ["width": result.screenWidth, "height": result.screenHeight],
            "positioned": positioned,
            "ignored": ignored
        ]
    }

    guard let data = try? JSONSerialization.data(withJSONObject: root, options: [.prettyPrinted, .sortedKeys]) else {
        print("Failed to serialize window list JSON")
        return
    }

    let path = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".windowList.json")
    do {
        try data.write(to: path)
        print("Window list written to \(path.path)")
    } catch {
        print("Failed to write window list: \(error)")
    }
}

func arrangeWindowsSideBySide() {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    let accessibilityEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary)

    print("Accessibility enabled:", accessibilityEnabled)
    if !accessibilityEnabled {
        print("Please enable accessibility permissions in System Preferences > Privacy & Security > Accessibility")
        exit(1)
    }

    let collected = collectAllWindows()
    print("Total visible windows collected: \(collected.visible.count)")

    let screens = NSScreen.screens
    print("Displays found: \(screens.count)")

    var screenResults: [ScreenResult] = []

    for (i, screen) in screens.enumerated() {
        print("Screen \(i + 1): \(screen.frame)")
        let result = arrangeWindowsOnScreen(
            screenIndex: i + 1,
            screen: screen,
            allWindows: collected.visible,
            globalIgnored: collected.ignored
        )
        screenResults.append(result)
    }

    writeWindowListJSON(screenResults: screenResults)
}

arrangeWindowsSideBySide()
```
