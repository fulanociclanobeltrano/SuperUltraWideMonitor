# Exposé for MacOS

Step 1: Create the Script  
1. Open “Script Editor” and type the script below.  
2. Save it as `expose.scpt` and run it with:  
   ```bash
   osascript expose.scpt
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
   /usr/bin/osascript ~/Documents/expose.scpt
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

```applescript
-- Get screen dimensions
set screenInfo to do shell script "system_profiler SPDisplaysDataType | grep Resolution | head -1 | awk '{print $2, $4}'"
set screenWidth to word 1 of screenInfo as integer
set screenHeight to word 2 of screenInfo as integer

-- Initialize array for windows
set allWindows to {}

-- Collect visible windows using System Events
tell application "System Events"
    set appProcesses to application processes
    repeat with appProcess in appProcesses
        tell appProcess
            if visible is true then
                set appName to name
                try
                    if appName is "Google Chrome" then
                        tell application "Google Chrome"
                            repeat with win in windows
                                set winBounds to bounds of win
                                set xCoord to item 1 of winBounds
                                set widthHeight to {(item 3 of winBounds) - (item 1 of winBounds), (item 4 of winBounds) - (item 2 of winBounds)}
                                set newWindow to {win, xCoord, widthHeight, appName}
                                set end of allWindows to newWindow
                            end repeat
                        end tell
                    else
                        repeat with win in windows
                            set winBounds to {position of win, size of win}
                            set xCoord to item 1 of item 1 of winBounds
                            set widthHeight to item 2 of winBounds
                            set newWindow to {win, xCoord, widthHeight, appName}
                            set end of allWindows to newWindow
                        end repeat
                    end if
                on error
                end try
            end if
        end tell
    end repeat
end tell

-- Check if any windows were collected
if (count of allWindows) = 0 then return

-- Arrange windows
set numWindows to count allWindows
set desiredWidth to screenWidth / numWindows
set desiredHeight to screenHeight
set finalPositions to {}

repeat with i from 0 to (numWindows - 1)
    set end of finalPositions to {i * desiredWidth, 0}
end repeat

repeat with i from 1 to numWindows
    set winInfo to item i of allWindows
    set win to item 1 of winInfo
    set appName to item 4 of winInfo
    set targetPosition to item i of finalPositions
    set targetX to item 1 of targetPosition
    set targetY to item 2 of targetPosition
    
    tell application "System Events"
        if appName is "Google Chrome" then
            tell application "Google Chrome"
                try
                    set bounds of win to {targetX, targetY, targetX + desiredWidth, targetY + desiredHeight}
                end try
            end tell
        else
            tell application process appName
                try
                    set position of win to {targetX, targetY}
                    set size of win to {desiredWidth, desiredHeight}
                end try
            end tell
        end if
    end tell
end repeat
```