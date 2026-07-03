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

### f. First admin user — set-admin.js (no script exists yet)

No bootstrap admin script exists in the repo. `firestore.rules` references one, but it has not been created. Until it is, use the following one-off Node.js snippet. Save it anywhere outside the repo (e.g. `~/tools/set-admin.js`).

```javascript
// ~/tools/set-admin.js
// Usage: GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node set-admin.js <uid>
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'fema-b608b',
});

const uid = process.argv[2];
if (!uid) { console.error('Usage: node set-admin.js <uid>'); process.exit(1); }

(async () => {
  // 1. Set the custom claim — this is what Firestore rules read via
  //    request.auth.token.role
  await admin.auth().setCustomUserClaims(uid, { role: 'admin' });

  // 2. Mirror the role in Firestore so the client UI can read it without
  //    waiting for a token refresh
  await admin.firestore()
    .collection('users').doc(uid)
    .set({ role: 'admin' }, { merge: true });

  console.log(`Done. uid=${uid} is now admin.`);
  process.exit(0);
})().catch(err => { console.error(err); process.exit(1); });
```

Run it:

```bash
# Install firebase-admin once in the tools directory
mkdir -p ~/tools && cd ~/tools && npm init -y && npm install firebase-admin

# Export a service-account key downloaded from Firebase console →
# Project settings → Service accounts → Generate new private key
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json

# Find the uid in Firebase console → Authentication → Users
node set-admin.js <uid>
```

The user must **sign out and sign back in** after this so their ID token picks up the new custom claim.

---

## 4. Content seeding

See [README.md § Content seeding](README.md#content-seeding) for the full procedure.

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
