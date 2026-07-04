# RELEASE RUNBOOK — FEMA (com.fema.fema)

Firebase project: `fema-b608b`  
Android package: `com.fema.fema`  
Branch: `feat/mvp-release`

---

## 1. One-time: Generate & store the upload keystore

Run this command **once** and store the output file outside the repo (e.g. `~/keystores/fema-upload.jks`). Back it up to a password manager or secure cloud vault immediately — **losing this keystore before enrolling in Play App Signing means losing the app's identity on the Play Store**.

```bash
keytool -genkey -v \
  -keystore ~/keystores/fema-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias fema-upload
```

Then wire it into the build:

```bash
cp android/key.properties.example android/key.properties
# Edit android/key.properties — fill in all four values:
#   storeFile=/absolute/path/to/fema-upload.jks
#   storePassword=...
#   keyPassword=...
#   keyAlias=fema-upload   (already correct per the example)
```

`android/key.properties` is gitignored. Never commit it.

---

## 2. One-time: Google Play Console setup

1. Create app: package `com.fema.fema`, app name **FEMA**, default language, declaration (not a game).
2. **Play App Signing** — enroll immediately on the first upload (Dashboard → Setup → App integrity → Enroll). Google holds the final signing key; your upload key signs the AAB you submit.
3. **Internal testing track** — create the track, add tester email addresses, publish the first release there before moving to Closed/Open testing.
4. **Data safety questionnaire** (Policy → App content → Data safety):
   - The app collects email address, name, and usage data (attendance records, course progress).
   - **Account deletion**: the UI flow exists and the `deleteAccount` Cloud Function is implemented (`functions/src/index.ts`), but it is **not yet deployed** (requires the Firebase Blaze plan). Currently, tapping "Delete my account" shows a "coming soon" message and signs the user out — data is not deleted. Declare deletion as "supported" but note it depends on contacting support / a pending deployment until the function is live. Update this declaration after deploying the function.
5. **Content rating questionnaire** — complete the IARC questionnaire to unlock distribution.
6. **Privacy policy** — a URL to your privacy policy is required before publishing. Add it under App content → Privacy policy.

---

## 3. One-time: Firebase console (project fema-b608b)

### a. Enable Cloud Storage and deploy rules

In the Firebase console, navigate to **Build → Storage** and click **Get started** (accept default rules, then immediately overwrite them). Then deploy the real rules:

```bash
firebase deploy --only storage
```

`storage.rules` at the repo root contains the production rules and is registered in `firebase.json`.

### b. Deploy Firestore rules

```bash
firebase deploy --only firestore:rules
```

### c. Deploy the deleteAccount function (Blaze plan required)

The `deleteAccount` callable function is fully implemented in `functions/src/index.ts` but **requires the Firebase Blaze (pay-as-you-go) plan** before it can be deployed. Upgrade the project billing plan first, then:

```bash
firebase deploy --only functions
```

After deployment, the in-app "Delete my account" button will perform full deletion (anonymises authored content, deletes the Firestore profile, deletes the Auth user). Update your Play Data safety declaration accordingly.

### d. App Check — Play Integrity provider

1. Firebase console → **App Check** (left nav) → **Android app → Play Integrity** — register.
2. Play Console → **Release → App integrity** — copy the **release** SHA-256 certificate fingerprint (available after the first signed build is uploaded).
3. Firebase console → **Project settings → Your apps → Android (com.fema.fema) → Add fingerprint** — paste the SHA-256.
4. Download the updated `google-services.json` and replace `android/app/google-services.json` if it changed.

### e. Crashlytics

No manual step required. Crash reports appear in the Firebase console after the first crash or forced test-crash from a release build.

### f. First admin user — tool/set-admin.js

The bootstrap script lives at `tool/set-admin.js` and accepts a uid **or** an
email address (the account must have signed in to the app at least once):

```bash
cd tool && npm install
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
node set-admin.js <uid-or-email>
```

It sets the `role: 'admin'` custom claim (what `firestore.rules` reads via
`request.auth.token.role`) and mirrors the role into the user's
`users/{uid}` doc so the client UI picks it up without a token refresh.

The user must **sign out and sign back in** after this so their ID token picks up the new custom claim.

---

## 4. Content seeding

Use the seed script (idempotent, safe to re-run):

```bash
cd tool && npm install
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
node seed-course.js                                       # 2 demo courses, no videos yet
node seed-course.js --video-url "<storage-download-url>"  # re-run once Storage has an MP4
```

See [README.md § Content seeding](README.md#content-seeding) for the manual console procedure.

At minimum, seed **one course and one lesson with a `videoUrl`** pointing to a Firebase Storage download URL before inviting internal testers, so the core watch flow is testable end-to-end.

---

## 5. Each release

### Bump the version

In `pubspec.yaml`, update `version:`. The format is `<semver>+<build-number>` where the build number must be strictly increasing (Play Store rejects a re-used build number):

```
version: 1.0.0+1   →   1.0.0+2   (patch only)
         1.0.0+2   →   1.1.0+3   (minor feature bump)
```

### Build the release AAB

```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### On-device smoke test before uploading

Install the release APK directly to a connected device and verify these flows manually:

```bash
flutter build apk --release
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

Checklist:
- [ ] Intro / onboarding screens render correctly
- [ ] Sign-in succeeds (requires live network)
- [ ] Guest browse works (unauthenticated library view)
- [ ] Video plays end-to-end (requires a seeded `videoUrl`)
- [ ] Teacher attendance save round-trips to Firestore
- [ ] Admin console is reachable for an admin-role account
- [ ] Course wizard end-to-end (requires deployed `storage.rules`): teacher
      creates a course, uploads a video with transcript, attaches a
      worksheet, publishes — course appears in the student library and the
      video, transcript, and worksheet all open
- [ ] Unpublishing the course removes it from the student library

### Upload to Play Console

Upload `build/app/outputs/bundle/release/app-release.aab` to the **Internal testing** track. Add release notes. Roll out to testers.

---

## 6. Rollback

In Play Console → Internal testing → the release → **Pause rollout** (or halt the release). The previous AAB remains available to testers. No Firebase action is needed unless you also need to roll back Firestore rules or Functions — for those, redeploy the prior version from git.

---

## Verified claims

| Claim | Result |
|---|---|
| `storage.rules` exists at repo root | Yes |
| `firebase.json` registers `storage.rules` | Yes — `"storage": { "rules": "storage.rules" }` |
| `README.md` has "Content seeding" section | Yes — line 22 |
| `android/key.properties.example` exists with alias `fema-upload` | Yes |
| Bootstrap admin script exists (scripts/, tool/, functions/) | **No** — `firestore.rules` references one but it does not exist; inline snippet provided above |
| `deleteAccount` Cloud Function implemented | Yes — `functions/src/index.ts` |
| `deleteAccount` currently deployed / working in-app | **No** — screen explicitly shows "coming soon" SnackBar + signs user out as fallback (Blaze plan required to deploy) |
