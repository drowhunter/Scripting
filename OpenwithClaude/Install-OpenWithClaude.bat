@echo off
setlocal enabledelayedexpansion
title Install "Open with Claude Desktop"

echo Searching for Claude Desktop...

set "CLAUDE_EXE="

REM Common Squirrel-style install location
if exist "%LOCALAPPDATA%\AnthropicClaude\claude.exe" (
    set "CLAUDE_EXE=%LOCALAPPDATA%\AnthropicClaude\claude.exe"
)

REM Fallback: search under LOCALAPPDATA\Programs
if not defined CLAUDE_EXE (
    for /f "delims=" %%F in ('dir /b /s "%LOCALAPPDATA%\Programs\claude.exe" 2^>nul') do (
        set "CLAUDE_EXE=%%F"
        goto :found
    )
)

REM Fallback: search under LOCALAPPDATA\AnthropicClaude (versioned app-x.y.z folders)
if not defined CLAUDE_EXE (
    for /f "delims=" %%F in ('dir /b /s "%LOCALAPPDATA%\AnthropicClaude\claude.exe" 2^>nul') do (
        set "CLAUDE_EXE=%%F"
        goto :found
    )
)

REM Fallback: search Program Files
if not defined CLAUDE_EXE (
    for /f "delims=" %%F in ('dir /b /s "%ProgramFiles%\Claude\claude.exe" 2^>nul') do (
        set "CLAUDE_EXE=%%F"
        goto :found
    )
)

:found
if not defined CLAUDE_EXE (
    echo.
    echo Could not automatically find claude.exe.
    set /p CLAUDE_EXE="Enter the full path to claude.exe: "
)

if not exist "%CLAUDE_EXE%" (
    echo.
    echo ERROR: "%CLAUDE_EXE%" does not exist. Aborting.
    pause
    exit /b 1
)

echo.
echo Using Claude Desktop at:
echo   %CLAUDE_EXE%
echo.

REM Right-click on a folder itself
reg add "HKCU\Software\Classes\Directory\shell\OpenWithClaude" /ve /d "Open with Claude Desktop" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\OpenWithClaude" /v "Icon" /d "\"%CLAUDE_EXE%\"" /f >nul
reg add "HKCU\Software\Classes\Directory\shell\OpenWithClaude\command" /ve /d "\"%CLAUDE_EXE%\" \"%%1\"" /f >nul

REM Right-click on empty space inside a folder (background)
reg add "HKCU\Software\Classes\Directory\Background\shell\OpenWithClaude" /ve /d "Open with Claude Desktop" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\OpenWithClaude" /v "Icon" /d "\"%CLAUDE_EXE%\"" /f >nul
reg add "HKCU\Software\Classes\Directory\Background\shell\OpenWithClaude\command" /ve /d "\"%CLAUDE_EXE%\" \"%%V\"" /f >nul

echo.
echo Done! Right-click any folder and choose "Open with Claude Desktop".
echo Run Uninstall-OpenWithClaude.bat to remove this context menu entry.
echo.
pause
