import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/firestore_service.dart';
import '../../auth/domain/auth_repository.dart';

enum UserRole { student, parent, teacher, admin, none }

class ChildProfile {
  final String? fullName;
  final String? gender;
  final DateTime? birthDate;
  final String? username;
  final String? password;
  final String? grade;
  final List<String> confidentSubjects;
  final List<String> improvementSubjects;
  final List<String> learningGoals;

  ChildProfile({
    this.fullName,
    this.gender,
    this.birthDate,
    this.username,
    this.password,
    this.grade,
    this.confidentSubjects = const [],
    this.improvementSubjects = const [],
    this.learningGoals = const [],
  });

  ChildProfile copyWith({
    String? fullName,
    String? gender,
    DateTime? birthDate,
    String? username,
    String? password,
    String? grade,
    List<String>? confidentSubjects,
    List<String>? improvementSubjects,
    List<String>? learningGoals,
  }) {
    return ChildProfile(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      username: username ?? this.username,
      password: password ?? this.password,
      grade: grade ?? this.grade,
      confidentSubjects: confidentSubjects ?? this.confidentSubjects,
      improvementSubjects: improvementSubjects ?? this.improvementSubjects,
      learningGoals: learningGoals ?? this.learningGoals,
    );
  }
}

class OnboardingState {
  final UserRole role;
  final String? grade; // Used for Student role
  final String? firstName;
  final String? surName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? password; // Parent/Teacher/Admin password
  final String? school;
  final String? lastGrade;
  final List<String> confidentSubjects; // Used for Student role
  final List<String> improvementSubjects; // Used for Student role
  final List<String> learningGoals; // Used for Student role
  final List<String> referralSources;
  final String? otherReferral;
  final bool quizSkipped;
  final int? quizScore;
  final int currentStep;
  
  // Parent specific
  final List<ChildProfile> children;
  final ChildProfile? activeChild; 

  // Educator specific
  final List<String> teachingGrades;
  final List<String> teachingSubjects;
  final String? pastSchools;
  final List<String> helpPreferences;
  final String? usesDigitalTools;
  final String? sharesContent;

  // Admin specific (User Creation flow)
  final String? invitedFullName;
  final String? invitedEmail;
  final String? invitedPhone;
  final String? invitedTempPassword;

  OnboardingState({
    this.role = UserRole.none,
    this.grade,
    this.firstName,
    this.surName,
    this.email,
    this.phone,
    this.gender,
    this.password,
    this.school,
    this.lastGrade,
    this.confidentSubjects = const [],
    this.improvementSubjects = const [],
    this.learningGoals = const [],
    this.referralSources = const [],
    this.otherReferral,
    this.quizSkipped = false,
    this.quizScore,
    this.currentStep = 1,
    this.children = const [],
    this.activeChild,
    this.teachingGrades = const [],
    this.teachingSubjects = const [],
    this.pastSchools,
    this.helpPreferences = const [],
    this.usesDigitalTools,
    this.sharesContent,
    this.invitedFullName,
    this.invitedEmail,
    this.invitedPhone,
    this.invitedTempPassword,
  });

  OnboardingState copyWith({
    UserRole? role,
    String? grade,
    String? firstName,
    String? surName,
    String? email,
    String? phone,
    String? gender,
    String? password,
    String? school,
    String? lastGrade,
    List<String>? confidentSubjects,
    List<String>? improvementSubjects,
    List<String>? learningGoals,
    List<String>? referralSources,
    String? otherReferral,
    bool? quizSkipped,
    int? quizScore,
    int? currentStep,
    List<ChildProfile>? children,
    ChildProfile? activeChild,
    List<String>? teachingGrades,
    List<String>? teachingSubjects,
    String? pastSchools,
    List<String>? helpPreferences,
    String? usesDigitalTools,
    String? sharesContent,
    String? invitedFullName,
    String? invitedEmail,
    String? invitedPhone,
    String? invitedTempPassword,
  }) {
    return OnboardingState(
      role: role ?? this.role,
      grade: grade ?? this.grade,
      firstName: firstName ?? this.firstName,
      surName: surName ?? this.surName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      gender: gender ?? this.gender,
      password: password ?? this.password,
      school: school ?? this.school,
      lastGrade: lastGrade ?? this.lastGrade,
      confidentSubjects: confidentSubjects ?? this.confidentSubjects,
      improvementSubjects: improvementSubjects ?? this.improvementSubjects,
      learningGoals: learningGoals ?? this.learningGoals,
      referralSources: referralSources ?? this.referralSources,
      otherReferral: otherReferral ?? this.otherReferral,
      quizSkipped: quizSkipped ?? this.quizSkipped,
      quizScore: quizScore ?? this.quizScore,
      currentStep: currentStep ?? this.currentStep,
      children: children ?? this.children,
      activeChild: activeChild ?? this.activeChild,
      teachingGrades: teachingGrades ?? this.teachingGrades,
      teachingSubjects: teachingSubjects ?? this.teachingSubjects,
      pastSchools: pastSchools ?? this.pastSchools,
      helpPreferences: helpPreferences ?? this.helpPreferences,
      usesDigitalTools: usesDigitalTools ?? this.usesDigitalTools,
      sharesContent: sharesContent ?? this.sharesContent,
      invitedFullName: invitedFullName ?? this.invitedFullName,
      invitedEmail: invitedEmail ?? this.invitedEmail,
      invitedPhone: invitedPhone ?? this.invitedPhone,
      invitedTempPassword: invitedTempPassword ?? this.invitedTempPassword,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final FirestoreService _firestoreService;
  final AuthRepository _authRepository;

  OnboardingNotifier(this._firestoreService, this._authRepository) : super(OnboardingState());

  void setRole(UserRole role) => state = state.copyWith(role: role, currentStep: 2);
  
  void setGrade(String grade) {
    if (state.role == UserRole.parent && state.activeChild != null) {
      state = state.copyWith(
        activeChild: state.activeChild!.copyWith(grade: grade),
      );
    } else {
      state = state.copyWith(grade: grade, currentStep: 3);
    }
  }

  void updatePersonalDetails({
    String? firstName,
    String? surName,
    String? email,
    String? phone,
    String? gender,
    String? password,
  }) {
    state = state.copyWith(
      firstName: firstName,
      surName: surName,
      email: email,
      phone: phone,
      gender: gender,
      password: password,
    );
  }

  void updateActiveChild(ChildProfile child) {
    state = state.copyWith(activeChild: child);
  }

  void saveActiveChild() {
    if (state.activeChild != null) {
      state = state.copyWith(
        children: [...state.children, state.activeChild!],
        activeChild: null,
      );
    }
  }

  void updateTeachingRole({
    List<String>? grades,
    List<String>? subjects,
    String? schools,
  }) {
    state = state.copyWith(
      teachingGrades: grades,
      teachingSubjects: subjects,
      pastSchools: schools,
    );
  }

  void updateSchoolDetails({
    String? school,
    String? grade,
  }) {
    state = state.copyWith(
      school: school,
      lastGrade: grade,
    );
  }

  void setHelpPreferences(List<String> preferences) {
    state = state.copyWith(helpPreferences: preferences);
  }

  void setPersonalizationAnswers({
    String? usesDigitalTools,
    String? sharesContent,
  }) {
    state = state.copyWith(
      usesDigitalTools: usesDigitalTools,
      sharesContent: sharesContent,
    );
  }

  void updateInvitedUserBasicInfo({
    String? fullName,
    String? email,
    String? phone,
  }) {
    state = state.copyWith(
      invitedFullName: fullName,
      invitedEmail: email,
      invitedPhone: phone,
    );
  }

  void updateInvitedUserTempPassword(String password) {
    state = state.copyWith(invitedTempPassword: password);
  }

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void previousStep() => state = state.copyWith(currentStep: state.currentStep - 1);
  void goToStep(int step) => state = state.copyWith(currentStep: step);
  
  void setConfidentSubjects(List<String> subjects) {
    if (state.role == UserRole.parent && state.activeChild != null) {
      state = state.copyWith(
        activeChild: state.activeChild!.copyWith(confidentSubjects: subjects),
      );
    } else {
      state = state.copyWith(confidentSubjects: subjects);
    }
  }

  void setImprovementSubjects(List<String> subjects) {
    if (state.role == UserRole.parent && state.activeChild != null) {
      state = state.copyWith(
        activeChild: state.activeChild!.copyWith(improvementSubjects: subjects),
      );
    } else {
      state = state.copyWith(improvementSubjects: subjects);
    }
  }

  void setLearningGoals(List<String> goals) {
    if (state.role == UserRole.parent && state.activeChild != null) {
      state = state.copyWith(
        activeChild: state.activeChild!.copyWith(learningGoals: goals),
      );
    } else {
      state = state.copyWith(learningGoals: goals);
    }
  }

  void setReferralSource(String source, String? other) {
    state = state.copyWith(
      referralSources: [source],
      otherReferral: other,
    );
  }

  void setQuizSkipped(bool skipped) {
    state = state.copyWith(quizSkipped: skipped);
  }

  void setQuizScore(int score) {
    state = state.copyWith(quizScore: score);
  }

  void skipToFinal() => state = state.copyWith(currentStep: 11);

  Future<void> completeOnboarding() async {
    final user = _authRepository.currentUser;
    if (user != null) {
      final userData = {
        'role': state.role.name,
        'grade': state.grade,
        'firstName': state.firstName,
        'surName': state.surName,
        'email': state.email,
        'phone': state.phone,
        'gender': state.gender,
        'school': state.school,
        'lastGrade': state.lastGrade,
        'confidentSubjects': state.confidentSubjects,
        'improvementSubjects': state.improvementSubjects,
        'learningGoals': state.learningGoals,
        'referralSources': state.referralSources,
        'otherReferral': state.otherReferral,
        'quizScore': state.quizScore,
        'quizSkipped': state.quizSkipped,
        'teachingGrades': state.teachingGrades,
        'teachingSubjects': state.teachingSubjects,
        'pastSchools': state.pastSchools,
        'helpPreferences': state.helpPreferences,
        'usesDigitalTools': state.usesDigitalTools,
        'sharesContent': state.sharesContent,
      };
      
      await _firestoreService.saveUserProfile(user.uid, userData);
    }
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return OnboardingNotifier(firestoreService, authRepository);
});

final homeTabProvider = StateProvider<int>((ref) => 0);
