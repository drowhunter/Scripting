@echo off
REM ============================================================
REM  uninstall-yt-dlp-context-menu.cmd
REM  Removes both "yt-dlp here" right-click menu entries added by
REM  install-yt-dlp-context-menu.cmd. Safe to run even if some of
REM  the keys are missing.
REM ============================================================
setlocal EnableExtensions

echo Removing "yt-dlp here" context menu entries...
echo.

reg delete "HKCU\Software\Classes\Directory\shell\yt-dlp here" /f >nul 2>nul
reg delete "HKCU\Software\Classes\Directory\Background\shell\yt-dlp here" /f >nul 2>nul
reg delete "HKCU\Software\Classes\Directory\shell\yt-dlp here (choose format)" /f >nul 2>nul
reg delete "HKCU\Software\Classes\Directory\Background\shell\yt-dlp here (choose format)" /f >nul 2>nul

echo Done.
echo.
pause
