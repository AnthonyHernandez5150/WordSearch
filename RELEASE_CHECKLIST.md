# WordTrail Release Checklist

## Google Play Console

- Create or use a Google Play developer account.
- New personal developer accounts generally need at least 12 opted-in closed-test users for 14 continuous days before applying for production access.
- Upload an Android App Bundle (`.aab`) to closed testing first.
- Add the public privacy policy text from `PRIVACY.md` to the store listing or hosted policy page.

## Signing

1. Create a private upload keystore and store it somewhere outside the Git repo.
2. Copy `android/key.properties.example` to `android/key.properties`.
3. Fill in the passwords, alias, and `storeFile` path.
4. Keep `android/key.properties` and the keystore private.

Suggested PowerShell commands to create an upload key on this Windows machine:

```powershell
New-Item -ItemType Directory -Force "$env:USERPROFILE\WordTrailKeys"
& "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -genkey -v -keystore "$env:USERPROFILE\WordTrailKeys\wordtrail-upload-key.jks" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Then set `android/key.properties` like this, using your real private passwords:

```properties
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=upload
storeFile=C:/Users/YOUR_WINDOWS_NAME/WordTrailKeys/wordtrail-upload-key.jks
```

## Build Checks

```powershell
flutter analyze
flutter build appbundle --release
```

The Play upload file will be:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Store Assets Still Needed

- App screenshots from a real phone.
- Feature graphic.
- Short description.
- Full description.
- Content rating questionnaire.
- Closed-test tester email list or Google Group.