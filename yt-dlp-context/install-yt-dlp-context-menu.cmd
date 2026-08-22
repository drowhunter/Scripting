@echo off
REM ============================================================
REM  install-yt-dlp-context-menu.cmd
REM
REM  Adds two "yt-dlp here" entries to the right-click menu for:
REM    - folders themselves (right-click a folder icon)
REM    - inside a folder (right-click empty space while browsing)
REM
REM    1) "yt-dlp here"                 - grabs a URL from your
REM       clipboard and downloads it with yt-dlp's default format
REM       choice into that folder.
REM
REM    2) "yt-dlp here (choose format)" - grabs a URL from your
REM       clipboard, lists available formats (yt-dlp -F), lets you
REM       type the format code you want, then downloads that
REM       format merged with the best available audio.
REM
REM  Installs to HKEY_CURRENT_USER, so no admin rights are needed
REM  and it only affects your Windows user account.
REM
REM  Keep this file together with yt-dlp-here.cmd and
REM  yt-dlp-choose-format.cmd in the same folder - the registry
REM  entries point at those scripts' full paths, wherever this
REM  installer is run from.
REM ============================================================
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
set "WORKER=%SCRIPT_DIR%yt-dlp-here.cmd"
set "WORKER2=%SCRIPT_DIR%yt-dlp-choose-format.cmd"

if not exist "%WORKER%" (
    echo Could not find yt-dlp-here.cmd next to this installer.
    echo Expected it at:
    echo   "%WORKER%"
    echo Keep all three files together in the same folder, then run this again.
    echo.
    pause
    exit /b 1
)

if not exist "%WORKER2%" (
    echo Could not find yt-dlp-choose-format.cmd next to this installer.
    echo Expected it at:
    echo   "%WORKER2%"
    echo Keep all three files together in the same folder, then run this again.
    echo.
    pause
    exit /b 1
)

echo Installing "yt-dlp here" context menu entries...
echo Worker script 1: "%WORKER%"
echo Worker script 2: "%WORKER2%"
echo.

set CMD1=\"%WORKER%\" \"%%1\"
set CMD2=\"%WORKER%\" \"%%V\"
set CMD3=\"%WORKER2%\" \"%%1\"
set CMD4=\"%WORKER2%\" \"%%V\"

REM --- "yt-dlp here" : right-click ON a folder ---
reg add "HKCU\Software\Classes\Directory\shell\yt-dlp here" /ve /d "yt-dlp here (clipboard URL)" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\yt-dlp here" /v Icon /d "shell32.dll,-16" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\yt-dlp here\command" /ve /d "%CMD1%" /f >nul

REM --- "yt-dlp here" : right-click INSIDE a folder (empty space) ---
reg add "HKCU\Software\Classes\Directory\Background\shell\yt-dlp here" /ve /d "yt-dlp here (clipboard URL)" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\yt-dlp here" /v Icon /d "shell32.dll,-16" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\yt-dlp here\command" /ve /d "%CMD2%" /f >nul

REM --- "yt-dlp here (choose format)" : right-click ON a folder ---
reg add "HKCU\Software\Classes\Directory\shell\yt-dlp here (choose format)" /ve /d "yt-dlp here (choose format)" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\yt-dlp here (choose format)" /v Icon /d "shell32.dll,-17" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\yt-dlp here (choose format)\command" /ve /d "%CMD3%" /f >nul

REM --- "yt-dlp here (choose format)" : right-click INSIDE a folder (empty space) ---
reg add "HKCU\Software\Classes\Directory\Background\shell\yt-dlp here (choose format)" /ve /d "yt-dlp here (choose format)" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\yt-dlp here (choose format)" /v Icon /d "shell32.dll,-17" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\yt-dlp here (choose format)\command" /ve /d "%CMD4%" /f >nul

echo Done.
echo.
echo Right-click a folder, or right-click empty space inside a folder:
echo   "yt-dlp here"                 - quick download, clipboard URL
echo   "yt-dlp here (choose format)" - lists formats, lets you pick one,
echo                                   downloads it + best audio
echo.
echo (To remove these later, run uninstall-yt-dlp-context-menu.cmd)
echo.
pause
