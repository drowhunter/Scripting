@echo off
title Uninstall "Open with Claude Desktop"

echo Removing "Open with Claude Desktop" context menu entries...

reg delete "HKCU\Software\Classes\Directory\shell\OpenWithClaude" /f >nul 2>&1
reg delete "HKCU\Software\Classes\Directory\Background\shell\OpenWithClaude" /f >nul 2>&1

echo.
echo Done.
echo.
pause
