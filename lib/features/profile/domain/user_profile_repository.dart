import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firestore_service.dart';
import '../../auth/domain/auth_repository.dart';
import '../../onboarding/domain/onboarding_provider.dart';
import 'user_profile.dart';

class UserProfileRepository {
  UserProfileRepository(this._firestoreService);

  final FirestoreService _firestoreService;

  Stream<AppUserProfile?> watchProfile(String uid) {
    return _firestoreService.watchUserProfileData(uid).map((data) {
      if (data == null) return null;
      return AppUserProfile.fromMap(uid, data);
    });
  }

  Future<void> saveProfile(AppUserProfile profile) async {
    await _firestoreService.saveUserProfile(profile.uid, profile.toMap());
  }

  Future<void> updateChildUsername(String uid, int childIndex, String username) async {
    await _firestoreService.updateChildUsername(uid, childIndex, username);
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository(ref.watch(firestoreServiceProvider));
});

final currentUserProfileProvider = StreamProvider<AppUserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.asData?.value;

  if (user == null) {
    return Stream.value(null);
  }

  return ref.watch(userProfileRepositoryProvider).watchProfile(user.uid);
});

final profileBackedOnboardingStateProvider = Provider<OnboardingState?>((ref) {
  final profile = ref.watch(currentUserProfileProvider).asData?.value;
  if (profile == null) return null;

  return OnboardingState(
    role: profile.role,
    grade: profile.grade,
    firstName: profile.firstName,
    surName: profile.surName,
    email: profile.email,
    phone: profile.phone,
    gender: profile.gender,
    school: profile.school,
    lastGrade: profile.lastGrade,
    confidentSubjects: profile.confidentSubjects,
    improvementSubjects: profile.improvementSubjects,
    learningGoals: profile.learningGoals,
    referralSources: profile.referralSources,
    otherReferral: profile.otherReferral,
    quizSkipped: profile.quizSkipped,
    quizScore: profile.quizScore,
    teachingGrades: profile.teachingGrades,
    teachingSubjects: profile.teachingSubjects,
    pastSchools: profile.pastSchools,
    helpPreferences: profile.helpPreferences,
    usesDigitalTools: profile.usesDigitalTools,
    sharesContent: profile.sharesContent,
    children: profile.children.map((child) => child.toOnboardingChild()).toList(),
  );
});
