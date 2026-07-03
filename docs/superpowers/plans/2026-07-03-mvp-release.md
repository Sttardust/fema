# FEMA MVP Release Engineering Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make FEMA shippable to the Play Store internal testing track: release manifest/signing/Crashlytics wired in code, release build verified, and a runbook for the console/ops steps — per the "Release engineering" section of `docs/superpowers/specs/2026-07-02-fema-mvp-design.md`.

**Architecture:** Code changes are deliberately small: manifest fixes, a standard `key.properties` signing config (falling back to debug signing when absent, so CI and other machines keep building), Crashlytics hooks in `main.dart` gated to non-debug + Firebase-ready. Everything that happens in consoles (Play, Firebase) goes into a RELEASE.md runbook executed by a human — agents must NOT attempt console operations.

**Decisions locked:** applicationId stays `com.fema.fema` (matches the existing Firebase Android app; permanent once uploaded). Version stays `1.0.0+1` for the first internal upload.

**Current state (verified):** `android/app/build.gradle.kts` (Kotlin DSL) signs release with debug keys, minify+shrink enabled; App Check already uses Play Integrity in non-debug (`lib/main.dart:23-30`); no Crashlytics; main `AndroidManifest.xml` lacks `INTERNET` permission (release builds would have NO network — debug builds get it injected); app label is lowercase "fema"; `android/.gitignore` already ignores `key.properties`/keystores.

**Branch:** `feat/mvp-release` (created from `main`).

---

### Task 1: Release manifest fixes

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml`

- [ ] **Step 1: Add the INTERNET permission** — inside `<manifest>` BEFORE `<application>`:

```xml
    <uses-permission android:name="android.permission.INTERNET"/>
```

Without this, release builds cannot reach Firebase or stream videos (debug/profile builds inject it, which is why it was never noticed).

- [ ] **Step 2: Fix the launcher label** — `android:label="fema"` → `android:label="FEMA"`.

- [ ] **Step 3: Verify** — `flutter build apk --debug` still builds; `grep -n "INTERNET\|android:label" android/app/src/main/AndroidManifest.xml` shows both changes.

- [ ] **Step 4: Commit** — `git add android/app/src/main/AndroidManifest.xml && git commit -m "fix(release): INTERNET permission and FEMA launcher label in main manifest"`

---

### Task 2: Release signing config

**Files:**
- Modify: `android/app/build.gradle.kts`
- Create: `android/key.properties.example`

- [ ] **Step 1: Wire signing in `build.gradle.kts`** (Kotlin DSL). At the top of the file, after the `plugins` block:

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
```

Inside `android { }`, add a `signingConfigs` block before `buildTypes` and update the release build type:

```kotlin
    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            // Falls back to debug signing when key.properties is absent so any
            // machine can still produce a runnable release build.
            signingConfig = if (hasReleaseKeystore)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")
        }
    }
```

Remove the two stale `// TODO:` comments (applicationId + signing) while in the file.

- [ ] **Step 2: Create `android/key.properties.example`** (committed template; the real file is gitignored):

```properties
# Copy to android/key.properties and fill in. NEVER commit the real file.
# Generate the keystore with:
#   keytool -genkey -v -keystore ~/fema-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias fema-upload
storePassword=CHANGE_ME
keyPassword=CHANGE_ME
keyAlias=fema-upload
storeFile=/absolute/path/to/fema-upload.jks
```

- [ ] **Step 3: Verify fallback path** — WITHOUT a key.properties present: `flutter build apk --release` must succeed (debug-signed, minified). This also smoke-tests R8/minification against firebase/video_player/chewie — if R8 fails with missing-class errors, add the minimal `android/app/proguard-rules.pro` keep rules the error output names and register via `proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")` in the release block; report what was needed.

- [ ] **Step 4: Commit** — `git add android/app/build.gradle.kts android/key.properties.example && git commit -m "feat(release): keystore-based release signing with debug fallback"`

---

### Task 3: Crashlytics

**Files:**
- Modify: `pubspec.yaml`
- Modify: `android/settings.gradle.kts` (or root `android/build.gradle.kts` — wherever the `com.google.gms.google-services` plugin version is declared; read both first and mirror that mechanism)
- Modify: `android/app/build.gradle.kts`
- Modify: `lib/main.dart`

- [ ] **Step 1: Add the dependency** — in pubspec.yaml under the other firebase packages:

```yaml
  firebase_crashlytics: ^6.0.3
```

`flutter pub get` (nearest resolvable version OK; report what resolved).

- [ ] **Step 2: Gradle wiring** — find where `com.google.gms.google-services` gets its version (likely `android/settings.gradle.kts` `plugins {}` block). Add the Crashlytics gradle plugin the same way, e.g. in settings.gradle.kts:

```kotlin
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
```

and in `android/app/build.gradle.kts` plugins block:

```kotlin
    id("com.google.firebase.crashlytics")
```

(If the project declares plugin versions differently, follow the existing google-services pattern exactly.)

- [ ] **Step 3: Hook Flutter errors in `main.dart`** — after the existing `FirebaseAppCheck.activate` call, still inside the `try` block:

```dart
    if (!kDebugMode) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
```

Imports: `package:firebase_crashlytics/firebase_crashlytics.dart` and `dart:ui` (for `PlatformDispatcher`; `kDebugMode` is already imported via foundation). Debug builds stay collection-off by default — do not enable collection in debug.

- [ ] **Step 4: Verify** — `flutter analyze` → "No issues found!"; `flutter test` → 51/51; `flutter build apk --release` → succeeds (Crashlytics gradle plugin runs during release build; a mapping-file upload warning without console setup is acceptable — report it).

- [ ] **Step 5: Commit** — `git add pubspec.yaml pubspec.lock android lib/main.dart && git commit -m "feat(release): Crashlytics crash reporting for non-debug builds"`

---

### Task 4: Release build verification + bundle

- [ ] **Step 1:** `flutter analyze` → "No issues found!"; `flutter test` → all pass.
- [ ] **Step 2:** `flutter build appbundle --release` → must produce `build/app/outputs/bundle/release/app-release.aab` (debug-signed if no keystore — fine for verification; the real upload happens after the runbook's keystore step).
- [ ] **Step 3:** Install the release APK variant on a device/emulator if available (`flutter build apk --release` + `adb install`): app must reach the intro screen, sign-in must work (network!), and browsing published courses as guest must work. This specifically validates the INTERNET-permission and R8 fixes. If no device is available, report that this remains on the runbook's checklist.
- [ ] **Step 4: Commit anything outstanding** (there should be nothing — verification only).

---

### Task 5: RELEASE.md runbook (human ops steps)

**Files:**
- Create: `RELEASE.md`

- [ ] **Step 1: Write the runbook** with these sections (concrete commands/console paths, concise):

1. **One-time: upload keystore** — the `keytool` command (as in key.properties.example), where to store the file (NOT in the repo; back it up), fill `android/key.properties`.
2. **One-time: Play Console** — create the app (package `com.fema.fema`), Internal testing track, add tester emails; complete the Data safety + Content rating questionnaires; privacy policy URL required (note: account deletion already implemented in-app — mention it in the Data safety form).
3. **One-time: Firebase console**
   - Enable **Cloud Storage** on project `fema-b608b`, then `firebase deploy --only storage` (rules already in repo).
   - `firebase deploy --only firestore:rules`.
   - **App Check**: register the Android app with the **Play Integrity** provider; add the Play App Signing SHA-256 certificate digest (from Play Console → App integrity) to the Firebase Android app settings; re-download `google-services.json` into `android/app/` if fingerprints changed.
   - **Crashlytics**: enable in console (first crash report activates the dashboard).
   - Provision the first **admin**: run the bootstrap admin script to set the admin custom claim (reference the repo's existing script/docs for it — locate it; if none exists, document the `firebase auth:` / Admin SDK snippet to set `{ role: 'admin' }` claims and mirror the `users/{uid}.role` doc field).
4. **Content seeding** — link to README's Content seeding section; upload at least one lesson MP4 under `lesson-videos/` and set its `videoUrl` before inviting testers.
5. **Each release** — bump `version` in pubspec.yaml (`1.0.0+2`, …); `flutter build appbundle --release`; upload the `.aab` to the Internal testing track; smoke-check the release APK on a device first (checklist: intro → sign-in (network) → guest browse → video plays → teacher attendance → admin console).
6. **Rollback** — pause the release in Play Console; previous internal build remains installable.

- [ ] **Step 2: Accuracy pass** — every repo path/command in the runbook must be real (storage.rules exists, README section exists, scripts referenced exist — verify each; if the bootstrap admin script does NOT exist in the repo, say so explicitly in the runbook and include the documented Admin SDK snippet instead of a phantom reference).

- [ ] **Step 3: Commit** — `git add RELEASE.md && git commit -m "docs(release): Play internal testing runbook"`

---

### Task 6: Full verification pass

- [ ] **Step 1:** `flutter analyze` → "No issues found!"; `flutter test` → all pass (51).
- [ ] **Step 2:** `flutter build appbundle --release` → succeeds.
- [ ] **Step 3:** Confirm no secrets in the diff: `git diff main..HEAD` contains no keystore files, no real passwords (key.properties.example has CHANGE_ME placeholders only); `git status` clean.
- [ ] **Step 4:** Push and open PR titled "MVP release engineering: signing, Crashlytics, release manifest, runbook".
