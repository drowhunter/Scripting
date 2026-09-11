#Requires AutoHotkey v1.1+

#^m::
    ; Get mouse position
    MouseGetPos, mx, my

    ; Determine target monitor
    SysGet, monCount, MonitorCount
    Loop, %monCount%
    {
        SysGet, mon, Monitor, %A_Index%
        if (mx >= monLeft && mx <= monRight && my >= monTop && my <= monBottom)
        {
            targetLeft := monLeft
            targetTop := monTop
            break
        }
    }

    ; Enumerate all windows
    WinGet, idList, List
    Loop, %idList%
    {
        this_id := idList%A_Index%

        ; Skip invisible or cloaked windows
        WinGet, style, Style, ahk_id %this_id%
        if !(style & 0x10000000) ; WS_VISIBLE
            continue

        ; Get window position
        WinGetPos, x, y, w, h, ahk_id %this_id%

        ; Move window to target monitor, preserving relative position
        newX := targetLeft + (x - A_ScreenLeft)
        newY := targetTop + (y - A_ScreenTop)

        WinMove, ahk_id %this_id%, , newX, newY
    }
return
