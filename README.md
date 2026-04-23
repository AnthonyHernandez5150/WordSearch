# WordTrail

WordTrail is a modern mobile word-search game built with Flutter and Dart. It is Android-first right now, with a branded dark UI, generated puzzle boards, swipe-based word selection, shaped boards, daily-style play, saved streaks, and difficulty profiles that change how words are hidden.

## Current Features

- Branded WordTrail splash, launcher icon, and dark mobile UI
- Calm, Explorer, and Expert difficulty profiles
- Curated puzzle topics with mixed word lengths
- Classic and shaped board styles
- Generated boards with filler letters and Expert decoys
- Swipe/drag word selection with found-word bursts
- Persistent lit solved words and board-complete flow
- Hint, restart, next-board, and home actions
- Saved progress for clears, daily streaks, clean streaks, hints, and best times

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

## Release Prep

- Android application id: `com.anthonyhernandez.wordtrailgame`.
- Release signing uses `android/key.properties`; see `RELEASE_CHECKLIST.md`.
- Google Play uploads should use an Android App Bundle (`.aab`).
- Keep `PRIVACY.md` updated before adding analytics, ads, purchases, reminders, online features, or cloud saves.
- Decide final free/premium puzzle-pack structure after the first closed test.

## Platform Status

Android is the active launch target. iOS, macOS, Linux, Windows, and web template folders may still contain default Flutter desktop/mobile placeholders and should be cleaned before those platforms are released.