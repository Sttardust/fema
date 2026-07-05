#!/usr/bin/env node
/**
 * Reproduces the wizard's createDraft write as a REAL teacher account would
 * perform it (Firestore users/{uid}.role == 'teacher', NO custom claim).
 *
 * Usage: GOOGLE_APPLICATION_CREDENTIALS=service-account.json node test-teacher-create.js
 * Exits 0 if the create is ALLOWED, 1 if PERMISSION_DENIED.
 */

const admin = require('firebase-admin');

const API_KEY = 'AIzaSyC2o57-N9LYM_I9sxhsPXDez6SQkOt8y0A';
const PROJECT = 'fema-b608b';
const TEST_UID = 'rules-test-teacher';

admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: PROJECT });

(async () => {
  // 1. Test fixture: auth user + teacher role in the users doc, NO claims —
  //    exactly what in-app signup produces.
  await admin.auth().createUser({ uid: TEST_UID }).catch(() => {}); // exists is fine
  await admin.auth().setCustomUserClaims(TEST_UID, null);
  await admin.firestore().collection('users').doc(TEST_UID)
      .set({ role: 'teacher', email: 'rules-test@example.invalid' }, { merge: true });

  // 2. Sign in as that user (custom token → idToken).
  const customToken = await admin.auth().createCustomToken(TEST_UID);
  const signIn = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    },
  ).then((r) => r.json());
  if (!signIn.idToken) throw new Error('sign-in failed: ' + JSON.stringify(signIn));

  // 3. Attempt the wizard's draft create as that user.
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/courses?documentId=rules-test-course`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${signIn.idToken}`,
      },
      body: JSON.stringify({
        fields: {
          title: { stringValue: 'rules test' },
          description: { stringValue: '' },
          subject: { stringValue: 'other' },
          grade: { stringValue: 'Grade 6' },
          ownerId: { stringValue: TEST_UID },
          status: { stringValue: 'draft' },
          thumbnailUrl: { stringValue: '' },
          rating: { integerValue: '0' },
          totalStudents: { integerValue: '0' },
        },
      }),
    },
  );

  const body = await res.json();
  if (res.ok) {
    console.log('ALLOWED — teacher create succeeded');
    // Clean up the created doc so reruns start fresh.
    await admin.firestore().doc('courses/rules-test-course').delete();
    process.exit(0);
  }
  console.log(`DENIED — ${res.status}: ${body.error?.status} ${body.error?.message}`);
  process.exit(1);
})().catch((e) => {
  console.error('Test harness error:', e.message);
  process.exit(2);
});
