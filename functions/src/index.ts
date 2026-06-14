import {onCall, HttpsError} from 'firebase-functions/v2/https';
import {initializeApp} from 'firebase-admin/app';
import {getAuth} from 'firebase-admin/auth';
import {getFirestore, FieldValue} from 'firebase-admin/firestore';

initializeApp();

const DELETED_USER_OWNER_ID = 'deleted-user';

/**
 * Deletes the calling user's account.
 *
 * Required by Apple App Store (Jun 2022) and Google Play (May 2024) for
 * any account-based app — users must be able to delete their account
 * from inside the app.
 *
 * Sequence:
 *   1. Anonymise content the user authored: courses → ownerId = 'deleted-user',
 *      classes → teacherId = 'deleted-user'. Their content survives but is
 *      no longer attributed to them.
 *   2. Delete the user's Firestore profile doc (users/{uid}).
 *   3. Delete the Firebase Auth user.
 *
 * Order matters: if we deleted the Auth user first, a partial failure
 * would leave orphaned Firestore data that the user can no longer reach
 * to clean up.
 */
export const deleteAccount = onCall(
  {region: 'us-central1', enforceAppCheck: false},
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'Sign in required.');
    }
    const uid = request.auth.uid;
    const db = getFirestore();
    const auth = getAuth();

    // 1. Anonymise authored content (best-effort — failures don't block delete).
    try {
      const courses = await db.collection('courses')
        .where('ownerId', '==', uid).get();
      const courseWrites = courses.docs.map((d) =>
        d.ref.update({
          ownerId: DELETED_USER_OWNER_ID,
          updatedAt: FieldValue.serverTimestamp(),
        })
      );
      const classes = await db.collection('classes')
        .where('teacherId', '==', uid).get();
      const classWrites = classes.docs.map((d) =>
        d.ref.update({
          teacherId: DELETED_USER_OWNER_ID,
          updatedAt: FieldValue.serverTimestamp(),
        })
      );
      await Promise.all([...courseWrites, ...classWrites]);
    } catch (e) {
      console.warn('Anonymisation step failed for', uid, e);
    }

    // 2. Delete the user's Firestore profile doc and notifications.
    try {
      const notifs = await db
        .collection('users').doc(uid)
        .collection('notifications').get();
      const notifDeletes = notifs.docs.map((d) => d.ref.delete());
      await Promise.all(notifDeletes);
      await db.collection('users').doc(uid).delete();
    } catch (e) {
      console.error('Failed to delete users/' + uid, e);
      throw new HttpsError('internal',
        'Failed to delete user profile. Try again.');
    }

    // 3. Delete the Auth user — last so retries on Firestore failures don't
    //    leave a dangling Auth account with no profile.
    try {
      await auth.deleteUser(uid);
    } catch (e) {
      console.error('Failed to delete Auth user ' + uid, e);
      throw new HttpsError('internal',
        'Profile deleted but Auth deletion failed. Contact support.');
    }

    return {success: true};
  }
);
