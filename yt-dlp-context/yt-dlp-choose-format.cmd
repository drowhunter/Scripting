@echo off
REM ============================================================
REM  yt-dlp-choose-format.cmd
REM  Worker script for the "yt-dlp here (choose format)" entry.
REM  Called automatically by the registry command - not meant to
REM  be run directly (though you can: pass a folder path as %1).
REM
REM  Uses the clipboard URL if there is one; otherwise prompts you
REM  to type/paste one. Lists available formats for it (yt-dlp
REM  -F), lets you type the format code you want, then downloads
REM  that format merged with the best available audio.
REM ============================================================
setlocal EnableExtensions

set "TARGETDIR=%~1"
if "%TARGETDIR%"=="" set "TARGETDIR=%CD%"

title yt-dlp here (choose format) - %TARGETDIR%

where yt-dlp >nul 2>nul
if errorlevel 1 (
    echo [yt-dlp here] yt-dlp.exe was not found on PATH.
    echo Install yt-dlp or add it to PATH, then try again.
    echo.
    pause
    exit /b 1
)

pushd "%TARGETDIR%" 2>nul
if errorlevel 1 (
    echo [yt-dlp here] Could not open folder:
    echo   %TARGETDIR%
    echo.
    pause
    exit /b 1
)

set "CLIPURL="
for /f "usebackq delims=" %%U in (`powershell -NoProfile -Command "$c=$null; try { $c=(Get-Clipboard -Raw -ErrorAction Stop) } catch { $c=$null }; if ($c) { $c=$c.Trim() } else { $c='' }; if ($c -match '(?im)https?://\S+') { $Matches[0] } else { '' }" 2^>nul`) do set "CLIPURL=%%U"

if not "%CLIPURL%"=="" if /i "%CLIPURL:~0,4%"=="http" goto :haveUrl

echo [yt-dlp here] No URL found on the clipboard.
set /p "CLIPURL=Enter the URL to download: "

if "%CLIPURL%"=="" (
    echo No URL entered. Aborting.
    echo.
    popd
    pause
    exit /b 1
)

if /i not "%CLIPURL:~0,4%"=="http" (
    echo [yt-dlp here] That doesn't look like a web link:
    echo   %CLIPURL%
    echo.
    popd
    pause
    exit /b 1
)

:haveUrl
echo [yt-dlp here] Listing available formats for:
echo   %CLIPURL%
echo.

yt-dlp -F "%CLIPURL%"

echo.
set "FMT="
set /p "FMT=Enter format code (or video,audio e.g. 137,140 - blank audio = best audio): "

if "%FMT%"=="" (
    echo No format entered. Aborting.
    echo.
    popd
    pause
    exit /b 1
)

set "VIDFMT="
set "AUDFMT="
echo %FMT%| findstr /C:"," >nul
if errorlevel 1 goto :singleFmt

for /f "tokens=1,2 delims=, " %%A in ("%FMT%") do (
    set "VIDFMT=%%A"
    set "AUDFMT=%%B"
)
if "%AUDFMT%"=="" set "AUDFMT=bestaudio"
set "COMBOFMT=%VIDFMT%+%AUDFMT%"
goto :gotFmt

:singleFmt
set "COMBOFMT=%FMT%+bestaudio"

:gotFmt
echo.
echo [yt-dlp here] Downloading format "%COMBOFMT%":
echo   %CLIPURL%
echo Into:
echo   %TARGETDIR%
echo.

yt-dlp --hls-use-mpegts --no-part --restrict-filenames -f "%COMBOFMT%" "%CLIPURL%" -c --socket-timeout 5

echo.
echo ------------------------------------------------------------
echo Done. Press any key to close this window.
popd
pause >nul
endlocal
