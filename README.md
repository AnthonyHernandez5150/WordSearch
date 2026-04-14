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

## Getting Started

Install Flutter, connect an Android device or start an emulator, then run:

```bash
flutter pub get
flutter run
```

## Quality Checks

```bash
flutter analyze
flutter build apk --debug --no-pub
```

## Android Debug Install

After building a debug APK, install it with Android Debug Bridge:

```bash
adb devices
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

A local helper script is also available for Windows development:

```powershell
tool\install_phone.bat
```

## Release Notes To Finish Later

- Replace the debug application id `com.example.wordsearch` before Play Store release.
- Add release signing instead of debug signing.
- Decide final free/premium puzzle-pack structure.
- Add persistent saved progress if the app should remember stats after reinstall.