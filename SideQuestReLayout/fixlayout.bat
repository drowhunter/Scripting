@echo off
setlocal
rem Usage: fixlayout.bat [backup folder] [output folder]
rem   Drag a backup folder onto this file, or double-click it to pick from a menu.
rem   Both parameters are optional and are passed to fixlayout.ps1.

set "BACKUPDIR=%~1"
set "OUTDIR=%~2"

rem A trailing backslash would escape the closing quote when passed to PowerShell
if not defined BACKUPDIR goto backupok
if "%BACKUPDIR:~-1%"=="\" set "BACKUPDIR=%BACKUPDIR:~0,-1%"
if "%BACKUPDIR:~-1%"==":" set "BACKUPDIR=%BACKUPDIR%\."
:backupok
if not defined OUTDIR goto outok
if "%OUTDIR:~-1%"=="\" set "OUTDIR=%OUTDIR:~0,-1%"
if "%OUTDIR:~-1%"==":" set "OUTDIR=%OUTDIR%\."
:outok

set "PSARGS="
if defined BACKUPDIR set PSARGS=-DroppedFolder "%BACKUPDIR%"
if defined OUTDIR set PSARGS=%PSARGS% -OutDir "%OUTDIR%"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0fixlayout.ps1" %PSARGS%

echo.
pause
