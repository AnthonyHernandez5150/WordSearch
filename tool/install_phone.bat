@echo off
setlocal
cd /d "%~dp0.."

set "ADB=C:\Users\mrtig\AppData\Local\Android\Sdk\platform-tools\adb.exe"
set "FLUTTER=C:\Users\mrtig\develop\flutter\bin\flutter.bat"
set "APK=build\app\outputs\flutter-apk\app-debug.apk"
set "PACKAGE=com.example.wordsearch"

echo.
echo == Checking phone connection ==
"%ADB%" devices
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Building debug APK ==
"%FLUTTER%" build apk --debug --no-pub
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Installing APK ==
"%ADB%" install -r "%APK%"
if errorlevel 1 exit /b %errorlevel%

echo.
echo == Launching WordTrail ==
"%ADB%" shell monkey -p %PACKAGE% -c android.intent.category.LAUNCHER 1
if errorlevel 1 exit /b %errorlevel%

echo.
echo WordTrail is installed and launched.