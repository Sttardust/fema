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
