; AutoHotKey script
; This script won't move windows, just expose them temporarily.
; Configure a button of your mouse to do 3 things:
; 1. press Ctrl+Shift+T.
; 2. wait 300ms
; 3. "exibir atividades (windows exposé)
; Put this .ahk file at C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Startup.

 ; Hotkey to trigger the function (Ctrl+Shift+T)
^+t::  ;
    ExposeWindows()
return

; Function to activate windows in approximate right-to-left order
ExposeWindows()
{
    WinGet, windowList, List
    windowArray := []

    Loop, %windowList% {
        currentWindowID := windowList%A_Index%
        WinGetTitle, title, ahk_id %currentWindowID%
        WinGet, state, MinMax, ahk_id %currentWindowID% ; Get window state (-1=minimized, 0=normal, 1=maximized)
        if (title != "" && state != -1 && !InStr(title, "Program Manager")) {
            WinGetPos, x, y, w, h, ahk_id %currentWindowID%
            window := Object()
            window["ID"] := currentWindowID
            window["X"] := x
            window["Y"] := y
            window["W"] := w
            window["H"] := h
            window["Title"] := title
            InsertSorted(windowArray, window)
        }
    }

    ; From right to left, just focus each window in the list
    Loop, % windowArray.Length() {
        index := windowArray.Length() - A_Index + 1
        window := windowArray[index]
        winID := window["ID"] ; Store in a separate variable for command syntax
        WinActivate, ahk_id %winID%
        ;Sleep, 200 ; Optional: delay between activations
    }
}

InsertSorted(ByRef arr, window) {
    ; Binary search for the correct position to insert the new window
    low := 1
    high := arr.MaxIndex()
    while (low <= high) {
        mid := (low + high) // 2
        if (arr[mid]["X"] < window["X"]) {
            low := mid + 1
        } else {
            high := mid - 1
        }
    }
    ; Insert the window at the correct position
    arr.InsertAt(low, window)
}


