# WordTrail

WordTrail is a modern mobile word-search game built with Flutter and Dart. It is Android-first right now, with a branded dark UI, generated puzzle boards, swipe-based word selection, shaped boards, daily-style play, and difficulty profiles that change how words are hidden.

## Current Features

- Branded WordTrail splash and dark mobile UI
- Calm, Explorer, and Expert difficulty profiles
- Curated puzzle topics with mixed word lengths
- Classic and shaped board styles
- Generated boards with filler letters and Expert decoys
- Swipe/drag word selection with found-word bursts
- Persistent lit solved words and board-complete flow
- Hint, restart, next-board, and home actions
- Session stats for clears, streaks, hints, and best times

## Project Location

The active working copy should live at:

```powershell
C:\dev\WordSearch_local
```

Avoid editing old Desktop or OneDrive copies. The phone-tested build comes from this folder.

## Fast Phone Test

With the phone plugged in and USB debugging allowed:

```powershell
C:\Users\mrtig\AppData\Local\Android\Sdk\platform-tools\adb.exe devices
C:\Users\mrtig\develop\flutter\bin\flutter.bat build apk --debug --no-pub
C:\Users\mrtig\AppData\Local\Android\Sdk\platform-tools\adb.exe install -r build\app\outputs\flutter-apk\app-debug.apk
C:\Users\mrtig\AppData\Local\Android\Sdk\platform-tools\adb.exe shell monkey -p com.example.wordsearch -c android.intent.category.LAUNCHER 1
```

Or run the helper script:

```powershell
tool\install_phone.bat
```

## Quality Checks

```powershell
C:\Users\mrtig\develop\flutter\bin\flutter.bat analyze
C:\Users\mrtig\develop\flutter\bin\flutter.bat build apk --debug --no-pub
```

## Release Notes To Finish Later

- Replace the debug application id `com.example.wordsearch` before Play Store release.
- Add release signing instead of debug signing.
- Decide final free/premium puzzle-pack structure.
- Add persistent saved progress if the app should remember stats after reinstall.