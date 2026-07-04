import 'package:flutter_test/flutter_test.dart';
import 'package:fema/routes/app_redirect.dart';
import 'package:fema/features/onboarding/domain/onboarding_provider.dart';

void main() {
  String? redirect(String loc,
          {bool loading = false,
          bool authed = false,
          bool profileLoading = false,
          UserRole? role}) =>
      computeRedirect(
        location: loc,
        isLoading: loading,
        isAuthenticated: authed,
        role: role,
        hasCompletedOnboarding: role != null && role != UserRole.none,
        isProfileLoading: profileLoading,
      );

  group('loading', () {
    test('any route bounces to splash while loading', () {
      expect(redirect('/home', loading: true), '/');
      expect(redirect('/', loading: true), null);
    });
    test('profile loading holds position instead of splashing', () {
      expect(redirect('/signup', authed: true, profileLoading: true), null);
      expect(redirect('/login', authed: true, profileLoading: true), null);
      expect(redirect('/', authed: true, profileLoading: true), null);
      expect(redirect('/onboarding', authed: true, profileLoading: true), null);
    });
  });

  group('guest (unauthenticated)', () {
    test('splash goes to intro', () => expect(redirect('/'), '/onboarding/intro'));
    test('can browse home and library', () {
      expect(redirect('/home'), null);
      expect(redirect('/library/course-details'), null);
    });
    test('blocked from protected surfaces', () {
      expect(redirect('/profile'), '/onboarding/intro');
      expect(redirect('/teacher/home'), '/onboarding/intro');
      expect(redirect('/admin/management'), '/onboarding/intro');
    });
    test('auth routes stay reachable', () => expect(redirect('/login'), null));
    test('intro stays put', () => expect(redirect('/onboarding/intro'), null));
  });

  group('authenticated, onboarding incomplete', () {
    test('splash and protected routes go to onboarding', () {
      expect(redirect('/', authed: true), '/onboarding');
      expect(redirect('/home', authed: true), '/onboarding');
      expect(redirect('/profile', authed: true), '/onboarding');
    });
    test('onboarding routes stay put', () {
      expect(redirect('/onboarding', authed: true), null);
      expect(redirect('/onboarding/grade', authed: true), null);
    });
    test('explicit none role treated as incomplete', () => expect(redirect('/home', authed: true, role: UserRole.none), '/onboarding'));
  });

  group('completed profiles land on role home', () {
    test('student', () {
      expect(redirect('/', authed: true, role: UserRole.student), '/home');
      expect(redirect('/login', authed: true, role: UserRole.student), '/home');
    });
    test('teacher', () {
      expect(redirect('/', authed: true, role: UserRole.teacher), '/teacher/home');
      expect(redirect('/onboarding', authed: true, role: UserRole.teacher), '/teacher/home');
    });
    test('admin', () {
      expect(redirect('/', authed: true, role: UserRole.admin), '/admin/management');
    });
    test('otp bounces authed student home', () => expect(redirect('/otp', authed: true, role: UserRole.student), '/home'));
  });

  group('role guards', () {
    test('student blocked from teacher and admin', () {
      expect(redirect('/teacher/home', authed: true, role: UserRole.student), '/home');
      expect(redirect('/admin/users', authed: true, role: UserRole.student), '/home');
    });
    test('teacher blocked from admin, admin from teacher', () {
      expect(redirect('/admin/management', authed: true, role: UserRole.teacher), '/home');
      expect(redirect('/teacher/home', authed: true, role: UserRole.admin), '/home');
    });
    test('teacher and admin can browse student surfaces', () {
      expect(redirect('/home', authed: true, role: UserRole.teacher), null);
      expect(redirect('/library', authed: true, role: UserRole.admin), null);
    });
    test('profile reachable for all roles', () {
      expect(redirect('/profile', authed: true, role: UserRole.student), null);
      expect(redirect('/profile', authed: true, role: UserRole.admin), null);
    });
  });
}
