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

-- display dialog "Screen Width: " & screenWidth & ", Screen Height: " & screenHeight

-- Initialize array for windows
set allWindows to {}

-- Collect visible windows using System Events
-- Collect visible windows using System Events
tell application "System Events"
  set appProcesses to application processes
  repeat with appProcess in appProcesses
    tell appProcess
      if visible is true then
        set appName to name
        try
          if appName is "Google Chrome" then
            -- Handle Google Chrome using its native AppleScript support
            tell application "Google Chrome"
              repeat with win in windows
                set winBounds to bounds of win
                set xCoord to item 1 of winBounds
                set widthHeight to {(item 3 of winBounds) - (item 1 of winBounds), (item 4 of winBounds) - (item 2 of winBounds)}
                
                -- Prepare the window entry
                set newWindow to {win, xCoord, widthHeight, appName}
                
                -- Insert the new window in sorted order
                set inserted to false
                repeat with i from 1 to count of allWindows
                  if xCoord < item 2 of item i of allWindows then
                    set allWindows to (items 1 thru (i - 1) of allWindows) & {newWindow} & (items i thru -1 of allWindows)
                    set inserted to true
                    exit repeat
                  end if
                end repeat
                
                -- If not inserted, append to the end
                if not inserted then
                  set end of allWindows to newWindow
                end if
              end repeat
            end tell
          else
            -- Handle other applications using System Events
            repeat with win in windows
              set winBounds to {position of win, size of win} -- Retrieve position and size
              set xCoord to item 1 of item 1 of winBounds
              set widthHeight to item 2 of winBounds
              
              -- Prepare the window entry
              set newWindow to {win, xCoord, widthHeight, appName}
              
              -- Insert the new window in sorted order
              set inserted to false
              repeat with i from 1 to count of allWindows
                if xCoord < item 2 of item i of allWindows then
                  set allWindows to (items 1 thru (i - 1) of allWindows) & {newWindow} & (items i thru -1 of allWindows)
                  set inserted to true
                  exit repeat
                end if
              end repeat
              
              -- If not inserted, append to the end
              if not inserted then
                set end of allWindows to newWindow
              end if
            end repeat
          end if
        on error
          -- Skip inaccessible windows
        end try
      end if
    end tell
  end repeat
end tell

-- Check if any windows were collected
if (count of allWindows) = 0 then
  -- display dialog "No windows found to arrange."
  return
end if

-- display dialog "Collected " & (count allWindows) & " windows."

-- Arrange windows
set numWindows to count allWindows
if numWindows ≤ 3 then
  set desiredWidth to screenWidth / 3
else
  set desiredWidth to screenWidth / numWindows
end if
set desiredHeight to screenHeight
set finalPositions to {}

-- Populate final positions
repeat with i from 0 to (numWindows - 1)
  set end of finalPositions to {i * desiredWidth, 0}
end repeat

-- Animate window movement and resizing
set steps to 5 -- Number of animation steps

-- Animate window movement and resizing
repeat with step from 1 to steps
  repeat with i from 1 to numWindows
    set winInfo to item i of allWindows
    set win to item 1 of winInfo
    set appName to item 4 of winInfo
    set targetPosition to item i of finalPositions
    if numWindows = 1 then
      set targetX to (screenWidth / 2) - (desiredWidth / 2)
    else if numWindows = 2 then
      if i = 1 then
        set targetX to (screenWidth / 2) - desiredWidth
      else if i = 2 then
        set targetX to (screenWidth / 2)
      end if
    else
      set targetX to item 1 of targetPosition -- Default behavior for more than 2 windows
    end if
    set targetY to item 2 of targetPosition
    
    tell application "System Events"
      if appName is "Google Chrome" then
        -- Handle Google Chrome window movement
        tell application "Google Chrome"
          try
            set initialBounds to bounds of win
            set initialX to item 1 of initialBounds
            set initialY to item 2 of initialBounds
            set initialWidth to (item 3 of initialBounds) - (item 1 of initialBounds)
            set initialHeight to (item 4 of initialBounds) - (item 2 of initialBounds)
            
            -- Calculate incremental bounds
            set newX to initialX + ((targetX - initialX) * step / steps)
            set newY to initialY + ((targetY - initialY) * step / steps)
            set newWidth to initialWidth + ((desiredWidth - initialWidth) * step / steps)
            set newHeight to initialHeight + ((desiredHeight - initialHeight) * step / steps)
            
            -- Apply new bounds
            set bounds of win to {newX, newY, newX + newWidth, newY + newHeight}
          on error errMsg
            -- Skip if bounds cannot be modified
          end try
        end tell
      else
        -- Handle other applications' windows
        tell application process appName
          try
            -- Get initial position and size
            set initialPosition to position of win
            set initialSize to size of win
            set initialX to item 1 of initialPosition
            set initialY to item 2 of initialPosition
            set initialWidth to item 1 of initialSize
            set initialHeight to item 2 of initialSize
            
            -- Calculate incremental positions and sizes
            set newX to initialX + ((targetX - initialX) * step / steps)
            set newY to initialY + ((targetY - initialY) * step / steps)
            set newWidth to initialWidth + ((desiredWidth - initialWidth) * step / steps)
            set newHeight to initialHeight + ((desiredHeight - initialHeight) * step / steps)
            
            -- Apply new position and size
            set position of win to {newX, newY}
            set size of win to {newWidth, newHeight}
          on error errMsg
            -- Skip if position or size cannot be modified
          end try
        end tell
      end if
    end tell
  end repeat
  
  -- delay 1.0E-3 -- Delay for smooth animation
end repeat

-- display dialog "Windows arranged and resized successfully."
```
