; AutoHotKey script
; Configure a button of your mouse to press Ctrl+Shift+Y.
; Put this .ahk file at C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup.
; Edit the values 5120 and/or 1440 bellow, which are my monitor resolution dimensions.

; Hotkey to trigger the function (Ctrl+Shift+Y)
^+y::
    ActivateWindowsSideBySide()
return

; Function to activate windows in approximate right-to-left order
ActivateWindowsSideBySide()
{
  WinGet, windowList, List
  windowArray := []
  Loop, %windowList% {
    currentWidthindowID := windowList%A_Index%
    WinGetTitle, title, ahk_id %currentWidthindowID%
    WinGet, state, MinMax, ahk_id %currentWidthindowID% ; Get window state (-1=minimized, 0=normal, 1=maximized)
    if (title != "" && state != -1 && !InStr(title, "Program Manager")) {
      WinGetPos, x, y, w, h, ahk_id %currentWidthindowID%
      window := {}
      window.ID := currentWidthindowID
      window.X := x
      window.Y := y
      window.W := w
      window.H := h
      window.Title := title
      InsertSorted(windowArray, window)
    }
  }
  windowArray.Sort(A_Index1.X < A_Index2.X ? -1 : (A_Index1.X > A_Index2.X ? 1 : 0))
 
  ScreenWidth := 5120
  NumWindows := windowArray.Length()
  if (NumWindows < 3)
    WindowWidth := ScreenWidth / 3
  else 
    WindowWidth := Floor(ScreenWidth / NumWindows)

  ; Outer loop for animation
  numberOfSteps := 20
  Loop, %numberOfSteps%
  {
    animStep := A_Index - 1
    for index, window in windowArray
    {
        title := window.Title
        left := (index - 1) * WindowWidth

        originalLeft := window.X
        if (NumWindows == 1)
            finalLeft := ScreenWidth/2 - (WindowWidth / 2)
        else if (NumWindows == 2 and index == 1)
            finalLeft := ScreenWidth/2 - WindowWidth
        else if (NumWindows == 2 and index == 2)
            finalLeft := ScreenWidth/2
        else
            finalLeft := (index - 1) * WindowWidth

        currentLeft := 0 + Round(originalLeft + ((finalLeft - originalLeft) / (numberOfSteps - animStep)))

        originalTop := window.Y
        finalTop := 0
        currentTop := 0 + Round(originalTop + ((finalTop - originalTop) / (numberOfSteps - animStep)))

        originalWidth := window.W
        finalWidth := WindowWidth
        currentWidth := 0 + Round(originalWidth + ((finalWidth - originalWidth) / (numberOfSteps - animStep)))

        originalHeight := window.H
        finalHeight := 1440
        currentHeight := 0 + Round(originalHeight + ((finalHeight - originalHeight) / (numberOfSteps - animStep)))

        ;WinMove, %title%, , %currentLeft%, %currentTop%, %currentWidth%, %currentHeight%
        HWND := WinExist(title)
        DllCall("SetWindowPos", UInt, HWND, Int, 0, Int, Round(currentLeft), Int, Round(currentTop), Int, Round(currentWidth), Int, Round(currentHeight), UInt, 0x0010 | 0x0040) ; SWP_NOSIZE | SWP_NOMOVE


        ;Sleep, 1
        
        ;THESE WORK!!!
        ;left := (index - 1) * WindowWidth
        ;title := window.Title
        ;WinMove, %title%, , %left%, 0, WindowWidth, 1400
    }
  }
}

InsertSorted(ByRef arr, window) {
    ; Binary search for the correct position to insert the new window
    low := 1
    high := arr.MaxIndex()
    while (low <= high) {
        mid := (low + high) // 2
        if (arr[mid].X < window.X) {
            low := mid + 1
        } else {
            high := mid - 1
        }
    }
    ; Insert the window at the correct position
    arr.InsertAt(low, window)
}

GetSortedArray(originalArray, sortFunction) {
    ; Create a copy of the original array
    sorted := []
    for index, obj in originalArray {
        sorted.Push(obj)
    }
    ; Sort the copy
    sorted.Sort(sortFunction)
    return sorted
}

SortByX(a, b) {
    if (a.X+0 < b.X+0)
        return -1
    else if (a.X+0 > b.X+0)
        return 1
    else
        return 0
}
