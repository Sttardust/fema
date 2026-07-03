import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'weak-password':
        return 'Password is too weak — use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No connection. Check your network and try again.';
      case 'invalid-verification-code':
        return 'That code is incorrect. Check the SMS and try again.';
      case 'session-expired':
        return 'The code expired. Tap Resend to get a new one.';
      case 'invalid-phone-number':
        return 'That phone number looks invalid.';
    }
  }
  return 'Something went wrong. Please try again.';
}
