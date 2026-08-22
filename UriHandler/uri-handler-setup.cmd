@echo off
setlocal EnableExtensions
title .uri handler setup

set "EXTKEY=HKCU\Software\Classes\.uri"
set "PROGKEY=HKCU\Software\Classes\UriListFile"
set "OPENWITH=HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.uri\OpenWithProgids"
set "DEST=%LOCALAPPDATA%\UriListHandler"
set "SCRIPT=%DEST%\open-uri.js"

echo.
echo   .uri file handler - opens every URL in a .uri file with your default browser
echo.

reg query "%PROGKEY%" >nul 2>&1
if errorlevel 1 goto :notinstalled

echo   Status: INSTALLED
echo.
choice /c YN /n /m "  Uninstall it? [Y/N] "
if errorlevel 2 goto :cancelled
goto :uninstall

:notinstalled
echo   Status: NOT INSTALLED
echo.
choice /c YN /n /m "  Install it? [Y/N] "
if errorlevel 2 goto :cancelled
goto :install

:install
if not exist "%~dp0open-uri.js" (
    echo.
    echo   ERROR: open-uri.js not found next to this script.
    goto :end
)

if not exist "%DEST%" mkdir "%DEST%"
copy /y "%~dp0open-uri.js" "%SCRIPT%" >nul
if errorlevel 1 (
    echo.
    echo   ERROR: could not copy open-uri.js to "%DEST%".
    goto :end
)

call :geticon
echo.
echo   Installing...

reg add "%EXTKEY%" /ve /t REG_SZ /d "UriListFile" /f >nul
reg add "%EXTKEY%" /v "PerceivedType" /t REG_SZ /d "text" /f >nul
reg add "%EXTKEY%\OpenWithProgids" /v "UriListFile" /t REG_SZ /d "" /f >nul
reg add "%PROGKEY%" /ve /t REG_SZ /d "URL List" /f >nul
reg add "%PROGKEY%" /v "FriendlyTypeName" /t REG_SZ /d "URL List" /f >nul
reg add "%PROGKEY%\DefaultIcon" /ve /t REG_SZ /d "%ICON%" /f >nul
reg add "%PROGKEY%\shell" /ve /t REG_SZ /d "open" /f >nul
reg add "%PROGKEY%\shell\open" /ve /t REG_SZ /d "Open all links" /f >nul
reg add "%PROGKEY%\shell\open\command" /ve /t REG_SZ /d "%SystemRoot%\System32\wscript.exe \"%SCRIPT%\" \"%%1\"" /f >nul
reg add "%PROGKEY%\shell\edit" /ve /t REG_SZ /d "Edit" /f >nul
reg add "%PROGKEY%\shell\edit\command" /ve /t REG_SZ /d "%SystemRoot%\System32\notepad.exe \"%%1\"" /f >nul

ie4uinit.exe -show
echo   Done. Icon: %ICON%
goto :end

:uninstall
echo.
echo   Uninstalling...

reg delete "%EXTKEY%" /f >nul 2>&1
reg delete "%PROGKEY%" /f >nul 2>&1
reg delete "%OPENWITH%" /v "UriListFile" /f >nul 2>&1
if exist "%DEST%" rd /s /q "%DEST%"

ie4uinit.exe -show
echo   Done.
goto :end

:geticon
rem Uses the default browser's own executable icon, falling back to the generic globe.
set "ICON=%SystemRoot%\System32\shell32.dll,14"
set "PROGID="
for /f "tokens=3" %%a in ('reg query "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" /v ProgId 2^>nul') do set "PROGID=%%a"
if not defined PROGID goto :eof
set "BROWSERCMD="
for /f "tokens=2,*" %%a in ('reg query "HKCR\%PROGID%\shell\open\command" /ve 2^>nul ^| findstr /i "REG_SZ"') do set "BROWSERCMD=%%b"
if not defined BROWSERCMD goto :eof
for /f tokens^=1^ delims^=^" %%a in ("%BROWSERCMD%") do if exist "%%a" set "ICON=%%a,0"
goto :eof

:cancelled
echo.
echo   Cancelled.

:end
echo.
pause
endlocal
