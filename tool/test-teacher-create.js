#!/usr/bin/env node
/**
 * Live rules check: performs the app's create writes (courses + classes) as
 * (a) a REAL teacher account — users/{uid}.role == 'teacher', NO custom
 * claim, exactly what in-app signup produces — and (b) an admin account
 * (role:'admin' claim + doc, what tool/set-admin.js produces).
 *
 * Usage: GOOGLE_APPLICATION_CREDENTIALS=service-account.json node test-teacher-create.js
 * Exits 0 if all four creates are ALLOWED, 1 otherwise.
 */

const admin = require('firebase-admin');

const API_KEY = 'AIzaSyC2o57-N9LYM_I9sxhsPXDez6SQkOt8y0A';
const PROJECT = 'fema-b608b';

admin.initializeApp({ credential: admin.credential.applicationDefault(), projectId: PROJECT });

async function signInAs(uid, claims, docRole) {
  await admin.auth().createUser({ uid }).catch(() => {});
  await admin.auth().setCustomUserClaims(uid, claims);
  await admin.firestore().collection('users').doc(uid)
      .set({ role: docRole, email: `${uid}@example.invalid` }, { merge: true });
  const customToken = await admin.auth().createCustomToken(uid);
  const signIn = await fetch(
    `https://identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=${API_KEY}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ token: customToken, returnSecureToken: true }),
    },
  ).then((r) => r.json());
  if (!signIn.idToken) throw new Error('sign-in failed: ' + JSON.stringify(signIn));
  return signIn.idToken;
}

async function tryCreate(idToken, collection, docId, fields) {
  const res = await fetch(
    `https://firestore.googleapis.com/v1/projects/${PROJECT}/databases/(default)/documents/${collection}?documentId=${docId}`,
    {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${idToken}` },
      body: JSON.stringify({ fields }),
    },
  );
  if (res.ok) await admin.firestore().doc(`${collection}/${docId}`).delete();
  return res.ok;
}

const courseFields = (uid) => ({
  title: { stringValue: 'rules test' },
  subject: { stringValue: 'other' },
  grade: { stringValue: 'Grade 6' },
  ownerId: { stringValue: uid },
  status: { stringValue: 'draft' },
});
const classFields = (uid) => ({
  name: { stringValue: 'rules test class' },
  teacherId: { stringValue: uid },
});

async function cleanup(uid) {
  await admin.firestore().doc(`users/${uid}`).delete();
  await admin.auth().deleteUser(uid).catch(() => {});
}

(async () => {
  const cases = [
    { uid: 'rules-test-teacher', claims: null, docRole: 'teacher' },
    { uid: 'rules-test-admin', claims: { role: 'admin' }, docRole: 'admin' },
  ];

  let allOk = true;
  for (const c of cases) {
    const idToken = await signInAs(c.uid, c.claims, c.docRole);
    const course = await tryCreate(idToken, 'courses', `rules-test-course-${c.uid}`, courseFields(c.uid));
    const klass = await tryCreate(idToken, 'classes', `rules-test-class-${c.uid}`, classFields(c.uid));
    console.log(`${c.docRole}: course create ${course ? 'ALLOWED' : 'DENIED'}, class create ${klass ? 'ALLOWED' : 'DENIED'}`);
    allOk = allOk && course && klass;
    await cleanup(c.uid);
  }
  process.exit(allOk ? 0 : 1);
})().catch((e) => {
  console.error('Test harness error:', e.message);
  process.exit(2);
});
