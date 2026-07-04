import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/auth_repository.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/email_signup_screen.dart';
import '../features/auth/presentation/email_login_screen.dart';
import '../features/auth/presentation/phone_signup_screen.dart';
import '../features/auth/presentation/phone_login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/onboarding/presentation/role_selection_screen.dart';
import '../features/onboarding/presentation/grade_selection_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/search_screen.dart';
import '../features/onboarding/presentation/fema_intro_screen.dart';
import '../features/library/presentation/library_screen.dart';
import '../features/library/presentation/course_details_screen.dart';
import '../features/library/presentation/video_player_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/profile/presentation/account_management_screen.dart';
import '../features/profile/presentation/about_us_screen.dart';
import '../features/home/presentation/management_placeholder_screen.dart';
import '../features/home/presentation/admin_home_screen.dart';
import '../features/teacher/presentation/class_management_screen.dart';
import '../features/teacher/presentation/teacher_home_screen.dart';
import '../features/teacher/course_editor/presentation/my_courses_screen.dart';
import '../features/teacher/course_editor/presentation/course_wizard_screen.dart';
import '../features/profile/domain/user_profile_repository.dart';
import 'app_redirect.dart';

/// Keeps the splash on screen for a minimum branding beat at cold start.
final splashGateProvider = FutureProvider<void>(
  (ref) => Future<void>.delayed(const Duration(seconds: 2)),
);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;
  final userProfile = ref.watch(currentUserProfileProvider);
  final splashDone = ref.watch(splashGateProvider).hasValue;

  final isLoading = authState.isLoading || !splashDone;
  final profile = userProfile.asData?.value;
  final hasCompletedOnboarding = profile?.hasCompletedOnboarding ?? false;

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) => computeRedirect(
      location: state.matchedLocation,
      isLoading: isLoading,
      isAuthenticated: user != null,
      role: profile?.role,
      hasCompletedOnboarding: hasCompletedOnboarding,
      isProfileLoading: user != null && userProfile.isLoading,
    ),
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const EmailSignupScreen(),
      ),
      GoRoute(
        path: '/signup-phone',
        builder: (context, state) => const PhoneSignupScreen(),
      ),
      GoRoute(
        path: '/login-phone',
        builder: (context, state) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final args = state.extra as Map<String, dynamic>? ?? const {};
          final verificationId = args['verificationId'] as String?;
          final redirectPath = args['redirectPath'] as String? ?? '/';
          final phoneNumber = args['phoneNumber'] as String? ?? '';

          if (verificationId == null) {
            return const FemaIntroScreen();
          }

          return OtpScreen(
            verificationId: verificationId,
            redirectPath: redirectPath,
            phoneNumber: phoneNumber,
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/grade',
        builder: (context, state) => const GradeSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/intro',
        builder: (context, state) => const FemaIntroScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => const SearchScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryScreen(),
      ),
      GoRoute(
        path: '/library/course-details',
        builder: (context, state) => const CourseDetailsScreen(),
      ),
      GoRoute(
        path: '/library/video-player',
        builder: (context, state) => const VideoPlayerScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'account-management',
            builder: (context, state) => const AccountManagementScreen(),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutUsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/teacher/home',
        builder: (context, state) => const TeacherHomeScreen(),
      ),
      GoRoute(
        path: '/teacher/classes',
        builder: (context, state) => const ClassManagementScreen(),
      ),
      GoRoute(
        path: '/teacher/courses',
        builder: (context, state) => const MyCoursesScreen(),
      ),
      GoRoute(
        path: '/teacher/course/new',
        builder: (context, state) => const CourseWizardScreen(),
      ),
      GoRoute(
        path: '/teacher/course/:courseId',
        builder: (context, state) =>
            CourseWizardScreen(courseId: state.pathParameters['courseId']),
      ),
      GoRoute(
        path: '/admin/management',
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: '/admin/users',
        builder: (context, state) => const ManagementPlaceholderScreen(
          title: 'Admin Console',
          description: 'Manage user roles, site configurations, and system-wide reports.',
          icon: Icons.admin_panel_settings_outlined,
        ),
      ),
      GoRoute(
        path: '/admin/analytics',
        builder: (context, state) => const ManagementPlaceholderScreen(
          title: 'System Analytics',
          description: 'Real-time metrics on user engagement, course popularity, and system health.',
          icon: Icons.analytics_outlined,
        ),
      ),
    ],
  );
});
