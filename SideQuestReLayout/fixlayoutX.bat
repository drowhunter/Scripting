@echo off
rem Same as fixlayout.bat, but the output folder defaults to X:\_Quest
rem Usage: fixlayoutX.bat [backup folder] [output folder]
setlocal
set "OUTDIR=%~2"
if not defined OUTDIR set "OUTDIR=X:\_Quest"
call "%~dp0fixlayout.bat" "%~1" "%OUTDIR%"
