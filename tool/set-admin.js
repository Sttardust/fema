#!/usr/bin/env node
/**
 * Provision an admin user for FEMA (RELEASE.md § 3f).
 *
 * Usage:
 *   cd tool && npm install
 *   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
 *   node set-admin.js <uid-or-email>
 *
 * The account must already exist in Firebase Auth (i.e. has signed in to the
 * app at least once). Sets the `role: 'admin'` custom claim — what
 * firestore.rules reads via request.auth.token.role — and mirrors the role
 * into users/{uid} so the client UI reflects it without a token refresh.
 * The user must sign out and back in afterwards to pick up the new claim.
 */

const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'fema-b608b',
});

const arg = process.argv[2];
if (!arg) {
  console.error('Usage: node set-admin.js <uid-or-email>');
  process.exit(1);
}

(async () => {
  const user = arg.includes('@')
    ? await admin.auth().getUserByEmail(arg)
    : await admin.auth().getUser(arg);

  await admin.auth().setCustomUserClaims(user.uid, { role: 'admin' });
  await admin
    .firestore()
    .collection('users')
    .doc(user.uid)
    .set({ role: 'admin' }, { merge: true });

  console.log(`Done. ${user.email ?? user.uid} (uid=${user.uid}) is now admin.`);
  console.log('They must sign out and back in for the claim to take effect.');
  process.exit(0);
})().catch((err) => {
  console.error('Failed:', err.message);
  process.exit(1);
});
