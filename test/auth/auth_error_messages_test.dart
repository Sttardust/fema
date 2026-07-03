import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/auth/domain/auth_error_messages.dart';

void main() {
  group('authErrorMessage', () {
    test('wrong-password → credential error copy', () {
      final e = FirebaseAuthException(code: 'wrong-password');
      expect(authErrorMessage(e), 'Email or password is incorrect.');
    });

    test('network-request-failed → network copy', () {
      final e = FirebaseAuthException(code: 'network-request-failed');
      expect(authErrorMessage(e), 'No connection. Check your network and try again.');
    });

    test('session-expired → session copy', () {
      final e = FirebaseAuthException(code: 'session-expired');
      expect(authErrorMessage(e), 'The code expired. Tap Resend to get a new one.');
    });

    test('unknown FirebaseAuthException code → fallback', () {
      final e = FirebaseAuthException(code: 'some-unknown');
      expect(authErrorMessage(e), 'Something went wrong. Please try again.');
    });

    test('plain Exception → fallback', () {
      final e = Exception('oops');
      expect(authErrorMessage(e), 'Something went wrong. Please try again.');
    });
  });
}
