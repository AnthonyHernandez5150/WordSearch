@echo off
setlocal
cd /d "%~dp0.."

set "ADB=adb"
set "FLUTTER=flutter"
set "APK=build\app\outputs\flutter-apk\app-debug.apk"
set "PACKAGE=com.anthonyhernandez.wordtrailgame"

where %ADB% >nul 2>nul
if errorlevel 1 (
  echo adb was not found on PATH.
  echo Install Android platform tools or add adb to PATH, then try again.
  exit /b 1
)

where %FLUTTER% >nul 2>nul
if errorlevel 1 (
  echo flutter was not found on PATH.
  echo Install Flutter or add Flutter to PATH, then try again.
  exit /b 1
)

echo.
echo == Checking phone connection ==
%ADB% devices
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Building debug APK ==
%FLUTTER% build apk --debug --no-pub
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Installing APK ==
%ADB% install -r "%APK%"
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Launching WordTrail ==
%ADB% shell monkey -p %PACKAGE% -c android.intent.category.LAUNCHER 1
if errorlevel 1 exit /b %errorlevel%

echo.
echo WordTrail is installed and launched.