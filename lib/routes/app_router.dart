import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/email_signup_screen.dart';
import '../features/auth/presentation/phone_signup_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/onboarding/presentation/role_selection_screen.dart';
import '../features/onboarding/presentation/parent_details_screen.dart';
import '../features/onboarding/presentation/child_secure_profile_screen.dart';
import '../features/onboarding/presentation/child_basic_profile_screen.dart';
import '../features/onboarding/presentation/child_profile_list_screen.dart';
import '../features/onboarding/presentation/grade_selection_screen.dart';
import '../features/onboarding/presentation/personal_details_screen.dart';
import '../features/onboarding/presentation/school_details_screen.dart';
import '../features/onboarding/presentation/subjects_selection_screen.dart';
import '../features/onboarding/presentation/learning_goals_screen.dart';
import '../features/onboarding/presentation/referral_source_screen.dart';
import '../features/onboarding/presentation/quiz_intro_screen.dart';
import '../features/onboarding/presentation/quiz_screen.dart';
import '../features/onboarding/presentation/teacher_onboarding_screens.dart';
import '../features/onboarding/presentation/admin_onboarding_screens.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/onboarding/presentation/fema_intro_screen.dart';

// Placeholder screens for router setup
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('Welcome to $title')),
    );
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const PlaceholderScreen(title: 'Login'),
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
        path: '/otp',
        builder: (context, state) {
          final verificationId = state.extra as String;
          return OtpScreen(verificationId: verificationId);
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/parent-details',
        builder: (context, state) => const ParentDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/child-secure',
        builder: (context, state) => const ChildSecureProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/child-basic',
        builder: (context, state) => const ChildBasicProfileScreen(),
      ),
      GoRoute(
        path: '/onboarding/child-list',
        builder: (context, state) => const ChildProfileListScreen(),
      ),
      GoRoute(
        path: '/onboarding/grade',
        builder: (context, state) => const GradeSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/details',
        builder: (context, state) => const PersonalDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/school',
        builder: (context, state) => const SchoolDetailsScreen(),
      ),
      GoRoute(
        path: '/onboarding/subjects-confident',
        builder: (context, state) => const SubjectsSelectionScreen(isConfident: true),
      ),
      GoRoute(
        path: '/onboarding/subjects-improve',
        builder: (context, state) => const SubjectsSelectionScreen(isConfident: false),
      ),
      GoRoute(
        path: '/onboarding/goals',
        builder: (context, state) => const LearningGoalsScreen(),
      ),
      GoRoute(
        path: '/onboarding/referral',
        builder: (context, state) => const ReferralSourceScreen(),
      ),
      GoRoute(
        path: '/onboarding/teacher-experience',
        builder: (context, state) => const TeacherExperienceScreen(),
      ),
      GoRoute(
        path: '/onboarding/teacher-personalization',
        builder: (context, state) => const TeacherPersonalizationScreen(),
      ),
      GoRoute(
        path: '/onboarding/admin-user-creation',
        builder: (context, state) => const AdminUserCreationScreen(),
      ),
      GoRoute(
        path: '/onboarding/admin-password',
        builder: (context, state) => const AdminPasswordSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/quiz-intro',
        builder: (context, state) => const QuizIntroScreen(),
      ),
      GoRoute(
        path: '/onboarding/quiz',
        builder: (context, state) => const QuizScreen(),
      ),
      GoRoute(
        path: '/onboarding/intro',
        builder: (context, state) => const FemaIntroScreen(),
      ),
      // Home route placeholder
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
  );
});
