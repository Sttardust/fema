# FEMA MVP Stabilization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Harden the trimmed + redesigned MVP for beta: extract and unit-test the router redirect matrix, consistent error/empty states on every Firestore-backed screen, working OTP resend, a fully clean `flutter analyze`, and widget tests for the critical paths — per the "Stabilization" section of `docs/superpowers/specs/2026-07-02-fema-mvp-design.md`.

**Architecture:** Test the highest-risk logic (router redirect) by extracting it into a pure function. Standardize UX for loading/error/empty via two small shared widgets, then sweep every `AsyncValue.when` to use them (no more silent `SizedBox.shrink()` failures). Everything else is targeted hardening, not new features.

**Tech Stack:** Flutter, Riverpod, go_router, flutter_test.

**Branch:** `feat/mvp-stabilization` (created from `main`).

---

### Task 1: Extract router redirect into a pure, tested function

**Files:**
- Create: `lib/routes/app_redirect.dart`
- Modify: `lib/routes/app_router.dart`
- Test: `test/routes/app_redirect_test.dart`

The redirect closure in `app_router.dart:41-98` is the app's security/UX backbone and is currently untestable. Extract it verbatim into a pure function.

- [ ] **Step 1: Write the failing test matrix**

Create `test/routes/app_redirect_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/routes/app_redirect.dart';
import 'package:fema/features/onboarding/domain/onboarding_provider.dart';

void main() {
  String? redirect(String loc, {bool loading = false, bool authed = false, UserRole? role}) =>
      computeRedirect(
        location: loc,
        isLoading: loading,
        isAuthenticated: authed,
        // role == null means "no profile yet" (onboarding incomplete)
        role: role,
        hasCompletedOnboarding: role != null && role != UserRole.none,
      );

  group('loading', () {
    test('any route bounces to splash while loading', () {
      expect(redirect('/home', loading: true), '/');
      expect(redirect('/', loading: true), null);
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
```

Run: `flutter test test/routes/app_redirect_test.dart` → FAIL (file missing).

- [ ] **Step 2: Extract `computeRedirect`**

Create `lib/routes/app_redirect.dart` — move the closure body verbatim, parameterized:

```dart
import '../features/onboarding/domain/onboarding_provider.dart';

/// Pure redirect logic for the app router. Mirrors GoRouter's redirect
/// contract: returns a location to redirect to, or null to stay.
String? computeRedirect({
  required String location,
  required bool isLoading,
  required bool isAuthenticated,
  required UserRole? role,
  required bool hasCompletedOnboarding,
}) {
  final isAuthRoute = location == '/login' ||
      location == '/signup' ||
      location == '/signup-phone' ||
      location == '/login-phone' ||
      location == '/otp';
  final isOnboardingRoute = location.startsWith('/onboarding');
  final isGuestBrowsable = location == '/home' ||
      location.startsWith('/home/') ||
      location == '/library' ||
      location.startsWith('/library/');
  final isStrictlyProtected = location == '/profile' ||
      location.startsWith('/teacher/') ||
      location.startsWith('/admin/');
  final isProtectedRoute = isGuestBrowsable || isStrictlyProtected;
  final isTeacherRoute = location.startsWith('/teacher/');
  final isAdminRoute = location.startsWith('/admin/');

  if (isLoading) {
    return location == '/' ? null : '/';
  }

  if (!isAuthenticated) {
    if (location == '/') return '/onboarding/intro';
    if (isStrictlyProtected) return '/onboarding/intro';
    return null;
  }

  if (!hasCompletedOnboarding) {
    if (location == '/') return '/onboarding';
    if (isProtectedRoute) return '/onboarding';
    return null;
  }

  if (isTeacherRoute && role != UserRole.teacher) return '/home';
  if (isAdminRoute && role != UserRole.admin) return '/home';

  if (location == '/' || isAuthRoute || isOnboardingRoute) {
    if (role == UserRole.teacher) return '/teacher/home';
    if (role == UserRole.admin) return '/admin/management';
    return '/home';
  }

  return null;
}
```

In `app_router.dart`, replace the redirect closure body with:

```dart
    redirect: (context, state) => computeRedirect(
      location: state.matchedLocation,
      isLoading: isLoading,
      isAuthenticated: user != null,
      role: profile?.role,
      hasCompletedOnboarding: hasCompletedOnboarding,
    ),
```

and add `import 'app_redirect.dart';`. Delete the now-inlined helper locals from the closure.

- [ ] **Step 3: Tests pass** — `flutter test` → all pass (15 prior + ~16 new). `flutter analyze` clean.
- [ ] **Step 4: Commit** — `git add lib/routes test/routes && git commit -m "test(router): extract computeRedirect and cover the role/guest matrix"`

---

### Task 2: Shared state widgets + token/helper dedupe

**Files:**
- Create: `lib/core/widgets/state_views.dart`
- Create: `lib/core/theme/subject_visuals.dart`
- Create: `lib/core/widgets/circle_icon_button.dart`
- Modify: `lib/core/theme/app_colors.dart` (add `dangerBorder`)
- Test: `test/core/widgets/state_views_test.dart`

- [ ] **Step 1: Failing test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fema/core/widgets/state_views.dart';

void main() {
  testWidgets('EmptyStateView renders icon and message', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: EmptyStateView(icon: Icons.school_outlined, message: 'No courses yet')),
    ));
    expect(find.text('No courses yet'), findsOneWidget);
  });

  testWidgets('ErrorStateView retry fires', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ErrorStateView(message: 'Could not load courses', onRetry: () => retried = true)),
    ));
    await tester.tap(find.text('Try again'));
    expect(retried, true);
  });
}
```

Run → FAIL.

- [ ] **Step 2: Implement**

`state_views.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({super.key, required this.icon, required this.message, this.action});
  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.greyLight),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(fontSize: 14, color: AppColors.grey)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: AppColors.greyLight),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: GoogleFonts.figtree(fontSize: 14, color: AppColors.grey)),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: Text('Try again',
                    style: GoogleFonts.figtree(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

`subject_visuals.dart` — single source for the subject→icon/tint mapping currently duplicated as private helpers in home_screen, search_screen, library_screen, teacher_home_screen (read one of them for the exact `CourseSubject` cases):

```dart
import 'package:flutter/material.dart';
import '../../features/library/domain/models.dart';
import 'app_colors.dart';

IconData subjectIcon(CourseSubject subject) {
  switch (subject) {
    case CourseSubject.math:
      return Icons.calculate_outlined;
    case CourseSubject.science:
      return Icons.science_outlined;
    case CourseSubject.english:
      return Icons.menu_book_outlined;
    case CourseSubject.socialStudies:
      return Icons.public_outlined;
    case CourseSubject.amharic:
      return Icons.translate_outlined;
    case CourseSubject.other:
      return Icons.school_outlined;
  }
}

Color subjectTint(CourseSubject subject) =>
    AppColors.subjectTints[subject.index % AppColors.subjectTints.length];
```

(Match the enum cases to the actual `CourseSubject` enum — adjust if it differs. `subjectTint` keyed by subject fixes the review note about tints shifting when lists are filtered.)

`circle_icon_button.dart` — the 40px circular surface button copy-pasted across ~7 screens:

```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CircleIconButton extends StatelessWidget {
  const CircleIconButton({super.key, required this.icon, required this.onTap, this.size = 40});
  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Icon(icon, size: size / 2, color: AppColors.textBody),
        ),
      ),
    );
  }
}
```

(If the shadow doesn't render under Material this way, use the existing screens' Container+InkWell structure — visual parity with today's back buttons is the acceptance bar.)

`app_colors.dart` — add:

```dart
  // Border for danger-zone cards and the sign-out row.
  static const Color dangerBorder = Color(0xFFF1D7D7);
```

- [ ] **Step 3: Swap usages** — replace the duplicated private `_subjectIcon` helpers and per-index tints with `subjectIcon`/`subjectTint` (home_screen, search_screen, library_screen, teacher_home_screen, course_details banner if applicable); replace hardcoded `Color(0xFFF1D7D7)` (profile_screen, account_management_screen, admin_home_screen) with `AppColors.dangerBorder`; replace `Colors.red.shade700` in class_management_screen with `AppColors.error`; replace the copy-pasted 40px back buttons with `CircleIconButton` (sign_up, phone screens, otp, grade_selection, course_details, video_player, account_management, search — wherever the pattern exists). Visual parity required — no layout shifts.
- [ ] **Step 4: Verify** — `flutter test` all pass; `flutter analyze` clean; quick `flutter run` visual spot-check if a device is handy.
- [ ] **Step 5: Commit** — `git add lib/core lib/features test/core && git commit -m "feat(stabilize): shared state views, subject visuals, circle button; dedupe tokens"`

---

### Task 3: Error/empty sweep on every Firestore-backed screen

**Files:**
- Modify: `lib/features/home/presentation/home_screen.dart`, `search_screen.dart`, `admin_home_screen.dart`
- Modify: `lib/features/library/presentation/library_screen.dart`, `course_details_screen.dart`, `video_player_screen.dart`
- Modify: `lib/features/teacher/presentation/teacher_home_screen.dart`, `class_management_screen.dart`

Audit every `AsyncValue.when(` in these files (grep `\.when(`) and enforce:

- [ ] **Step 1: No silent failures** — every `error:` branch renders `ErrorStateView(message: <screen-specific copy>, onRetry: () => ref.refresh(<the provider>))` (or `ref.invalidate`). Known offenders from review: teacher dashboard stats render `SizedBox.shrink()` on error; admin stats section hides on error. For inline sections where a full-height error view is too big (stats rows), a compact variant is fine: a `SoftCard` with the error copy + retry text button — but it must be VISIBLE, not blank.
- [ ] **Step 2: Empty states** — every empty-list branch uses `EmptyStateView` with the copy already established (e.g. "No courses yet", "No classes yet", "No students yet", search's idle prompt). Replace the ad-hoc empty widgets from the redesign with the shared widget (identical copy, identical look).
- [ ] **Step 3: Loading states** — confirm every `loading:` branch shows a progress indicator or skeleton, `color: AppColors.primary` — no blank frames.
- [ ] **Step 4: Course details deep-link guard** — course_details_screen and video_player_screen depend on `selectedCourseProvider`/`selectedLessonProvider`; both already guard null ("No lesson selected"). Restyle those guards with `EmptyStateView` + a "Browse library" `PillButton` action → `context.go('/home')`.
- [ ] **Step 5: Verify** — `flutter test` all pass; `flutter analyze` clean. Manual: airplane-mode the device/emulator and open each screen — visible error + working retry once back online (report if no device available).
- [ ] **Step 6: Commit** — `git add lib/features && git commit -m "feat(stabilize): visible error states with retry across Firestore screens"`

---

### Task 4: OTP resend + auth error message consistency

**Files:**
- Modify: `lib/features/auth/presentation/otp_screen.dart`
- Create: `lib/features/auth/domain/auth_error_messages.dart`
- Modify: `lib/features/auth/presentation/email_login_screen.dart`, `email_signup_screen.dart`, `phone_login_screen.dart`, `phone_signup_screen.dart`
- Test: `test/auth/auth_error_messages_test.dart`

- [ ] **Step 1: OTP resend actually works** — the "Resend" text (otp_screen.dart:173) is currently a no-op. Read how OtpScreen receives its params (verificationId, phone number, redirectPath via router `extra`). Implement: a 60s countdown (`Timer.periodic`, cancelled in dispose) starting on screen entry; while counting, show "Resend in 0:NN" (grey, non-tappable); at zero show "Resend" (primary 700, tappable) → calls `FirebaseAuth.verifyPhoneNumber` again with the SAME phone number and callbacks that update the screen's verificationId (mirror the phone screens' call — extract a small shared helper if cleaner), then restarts the countdown. Mounted-guard all callbacks. If the screen doesn't currently receive the raw phone number, thread it through the router `extra` from both phone screens (update their push calls accordingly).
- [ ] **Step 2: Friendly error copy** — create `auth_error_messages.dart`:

```dart
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
```

Unit test: 3-4 codes map to the right copy + unknown falls back (construct `FirebaseAuthException(code: 'wrong-password')` directly — no Firebase init needed).

- [ ] **Step 3: Use it** — in the four auth screens + OTP verify, route caught auth exceptions through `authErrorMessage(e)` in the existing SnackBars instead of raw `$e` / `e.message` (read each catch block; keep the SnackBar mechanics).
- [ ] **Step 4: Verify** — `flutter test` all pass; `flutter analyze` clean.
- [ ] **Step 5: Commit** — `git add lib/features/auth test/auth && git commit -m "feat(stabilize): working OTP resend with cooldown, friendly auth errors"`

---

### Task 5: Analyzer to absolute zero

**Files:**
- Modify: the 6 hidden screens with the 16 remaining info lints: `lib/features/notifications/presentation/notifications_screen.dart`, `lib/features/onboarding/presentation/{language_selection_screen,learning_goals_screen,personal_details_screen,referral_source_screen,teacher_onboarding_screens}.dart`

- [ ] **Step 1: Fix the 16 info lints** — mechanical only, no behavior change: `withOpacity(x)` → `withValues(alpha: x)`; `unnecessary_underscores` → name the params (`(context, index)`); the deprecated `Radio` `groupValue`/`onChanged` usages in referral_source_screen → wrap the radios in a `RadioGroup` ancestor per the Flutter deprecation notice, or if that refactor is disruptive inside a hidden screen, add a scoped `// ignore: deprecated_member_use` with a one-line reason comment (prefer the real fix; use the ignore only if the RadioGroup migration would require restructuring the screen's state).
- [ ] **Step 2: Verify** — `flutter analyze` → **"No issues found!"** (the actual string, zero infos). `flutter test` all pass.
- [ ] **Step 3: Commit** — `git add lib/features && git commit -m "chore(stabilize): zero out analyzer infos in hidden screens"`

---

### Task 6: Critical-path widget tests

**Files:**
- Create: `test/onboarding/grade_selection_screen_test.dart`
- Create: `test/home/home_screen_test.dart`
- Create: `test/teacher/class_management_test.dart` (scope per Step 3)

Provider-override based; no Firebase. Read how `test/library/video_player_screen_test.dart` fakes providers — reuse its approach/fixtures.

- [ ] **Step 1: Grade selection** — pump `GradeSelectionScreen` in ProviderScope (+ MaterialApp): asserts grade tiles render ("Grade 1" … "Grade 12"), Continue disabled until a tile is tapped, tapping "Grade 9" selects it (Continue enabled). Don't tap Continue (it hits Firebase via completeOnboarding); state assertions only.
- [ ] **Step 2: Home** — pump `HomeScreen` with `coursesProvider` overridden to a 2-course fixture and auth/profile providers overridden as a signed-in student (mirror the video test's override style; if `currentUserProfileProvider` is awkward to fake, pump `_StudentHomePage`'s parent with guest state instead and assert the guest greeting): assert greeting renders, both course titles render, chip "Math" filters the grid (course count changes), empty override renders "No courses yet".
- [ ] **Step 3: Class management** — read the screen's providers first: if `teacherClassesProvider` can be overridden with a fixture (2 classes, 3 students), pump and assert: class names render; Students tab shows class-name section headers; Attendance tab renders per-class sections. If the provider graph drags in Firestore construction that can't be overridden cleanly, write the test for whatever layer IS testable (e.g. the row widgets with direct data) and report the gap honestly instead of forcing it.
- [ ] **Step 4: Verify** — `flutter test` → all pass (target ≥ 25 total). `flutter analyze` → No issues found.
- [ ] **Step 5: Commit** — `git add test && git commit -m "test(stabilize): widget coverage for grade, home, and class management paths"`

---

### Task 7: Full verification pass

- [ ] **Step 1:** `flutter analyze` → "No issues found!" (zero, including infos).
- [ ] **Step 2:** `flutter test` → all pass; report total.
- [ ] **Step 3:** `flutter build apk --debug` → builds.
- [ ] **Step 4: Flow smoke (device/emulator if available):** guest browse → course → player unavailable-state; student signup → grade → home; search; teacher → attendance save + error snackbar (airplane mode); OTP resend countdown; admin console → users/analytics/profile/sign-out. Report what was verifiable.
- [ ] **Step 5:** Push and open PR titled "MVP stabilization: tested redirects, error states, OTP resend, zero-lint".
