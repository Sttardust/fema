import '../../onboarding/domain/onboarding_provider.dart';

class AppChildProfile {
  final String? fullName;
  final String? gender;
  final DateTime? birthDate;
  final String? username;
  final String? grade;
  final List<String> confidentSubjects;
  final List<String> improvementSubjects;
  final List<String> learningGoals;

  const AppChildProfile({
    this.fullName,
    this.gender,
    this.birthDate,
    this.username,
    this.grade,
    this.confidentSubjects = const [],
    this.improvementSubjects = const [],
    this.learningGoals = const [],
  });

  factory AppChildProfile.fromMap(Map<String, dynamic> data) {
    return AppChildProfile(
      fullName: data['fullName'] as String?,
      gender: data['gender'] as String?,
      birthDate: DateTime.tryParse((data['birthDate'] as String?) ?? ''),
      username: data['username'] as String?,
      grade: data['grade'] as String?,
      confidentSubjects: _readStringList(data['confidentSubjects']),
      improvementSubjects: _readStringList(data['improvementSubjects']),
      learningGoals: _readStringList(data['learningGoals']),
    );
  }

  factory AppChildProfile.fromOnboarding(ChildProfile child) {
    return AppChildProfile(
      fullName: child.fullName,
      gender: child.gender,
      birthDate: child.birthDate,
      username: child.username,
      grade: child.grade,
      confidentSubjects: child.confidentSubjects,
      improvementSubjects: child.improvementSubjects,
      learningGoals: child.learningGoals,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'username': username,
      'grade': grade,
      'confidentSubjects': confidentSubjects,
      'improvementSubjects': improvementSubjects,
      'learningGoals': learningGoals,
    };
  }

  ChildProfile toOnboardingChild() {
    return ChildProfile(
      fullName: fullName,
      gender: gender,
      birthDate: birthDate,
      username: username,
      grade: grade,
      confidentSubjects: confidentSubjects,
      improvementSubjects: improvementSubjects,
      learningGoals: learningGoals,
    );
  }

  AppChildProfile copyWith({
    String? fullName,
    String? gender,
    DateTime? birthDate,
    String? username,
    String? grade,
    List<String>? confidentSubjects,
    List<String>? improvementSubjects,
    List<String>? learningGoals,
  }) {
    return AppChildProfile(
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      username: username ?? this.username,
      grade: grade ?? this.grade,
      confidentSubjects: confidentSubjects ?? this.confidentSubjects,
      improvementSubjects: improvementSubjects ?? this.improvementSubjects,
      learningGoals: learningGoals ?? this.learningGoals,
    );
  }
}

class AppUserProfile {
  final String uid;
  final UserRole role;
  final String? grade;
  final String? firstName;
  final String? surName;
  final String? email;
  final String? phone;
  final String? gender;
  final String? school;
  final String? lastGrade;
  final List<String> confidentSubjects;
  final List<String> improvementSubjects;
  final List<String> learningGoals;
  final List<String> referralSources;
  final String? otherReferral;
  final bool quizSkipped;
  final int? quizScore;
  final List<String> teachingGrades;
  final List<String> teachingSubjects;
  final String? pastSchools;
  final List<String> helpPreferences;
  final String? usesDigitalTools;
  final String? sharesContent;
  final List<AppChildProfile> children;

  const AppUserProfile({
    required this.uid,
    required this.role,
    this.grade,
    this.firstName,
    this.surName,
    this.email,
    this.phone,
    this.gender,
    this.school,
    this.lastGrade,
    this.confidentSubjects = const [],
    this.improvementSubjects = const [],
    this.learningGoals = const [],
    this.referralSources = const [],
    this.otherReferral,
    this.quizSkipped = false,
    this.quizScore,
    this.teachingGrades = const [],
    this.teachingSubjects = const [],
    this.pastSchools,
    this.helpPreferences = const [],
    this.usesDigitalTools,
    this.sharesContent,
    this.children = const [],
  });

  factory AppUserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return AppUserProfile(
      uid: uid,
      role: _readRole(data['role'] as String?),
      grade: data['grade'] as String?,
      firstName: data['firstName'] as String?,
      surName: data['surName'] as String?,
      email: data['email'] as String?,
      phone: data['phone'] as String?,
      gender: data['gender'] as String?,
      school: data['school'] as String?,
      lastGrade: data['lastGrade'] as String?,
      confidentSubjects: _readStringList(data['confidentSubjects']),
      improvementSubjects: _readStringList(data['improvementSubjects']),
      learningGoals: _readStringList(data['learningGoals']),
      referralSources: _readStringList(data['referralSources']),
      otherReferral: data['otherReferral'] as String?,
      quizSkipped: data['quizSkipped'] as bool? ?? false,
      quizScore: (data['quizScore'] as num?)?.toInt(),
      teachingGrades: _readStringList(data['teachingGrades']),
      teachingSubjects: _readStringList(data['teachingSubjects']),
      pastSchools: data['pastSchools'] as String?,
      helpPreferences: _readStringList(data['helpPreferences']),
      usesDigitalTools: data['usesDigitalTools'] as String?,
      sharesContent: data['sharesContent'] as String?,
      children: (data['children'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((child) => AppChildProfile.fromMap(Map<String, dynamic>.from(child)))
          .toList(),
    );
  }

  factory AppUserProfile.fromOnboarding(String uid, OnboardingState state) {
    return AppUserProfile(
      uid: uid,
      role: state.role,
      grade: state.grade,
      firstName: state.firstName,
      surName: state.surName,
      email: state.email,
      phone: state.phone,
      gender: state.gender,
      school: state.school,
      lastGrade: state.lastGrade,
      confidentSubjects: state.confidentSubjects,
      improvementSubjects: state.improvementSubjects,
      learningGoals: state.learningGoals,
      referralSources: state.referralSources,
      otherReferral: state.otherReferral,
      quizSkipped: state.quizSkipped,
      quizScore: state.quizScore,
      teachingGrades: state.teachingGrades,
      teachingSubjects: state.teachingSubjects,
      pastSchools: state.pastSchools,
      helpPreferences: state.helpPreferences,
      usesDigitalTools: state.usesDigitalTools,
      sharesContent: state.sharesContent,
      children: state.children.map(AppChildProfile.fromOnboarding).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role.name,
      'grade': grade,
      'firstName': firstName,
      'surName': surName,
      'email': email,
      'phone': phone,
      'gender': gender,
      'school': school,
      'lastGrade': lastGrade,
      'confidentSubjects': confidentSubjects,
      'improvementSubjects': improvementSubjects,
      'learningGoals': learningGoals,
      'referralSources': referralSources,
      'otherReferral': otherReferral,
      'quizScore': quizScore,
      'quizSkipped': quizSkipped,
      'teachingGrades': teachingGrades,
      'teachingSubjects': teachingSubjects,
      'pastSchools': pastSchools,
      'helpPreferences': helpPreferences,
      'usesDigitalTools': usesDigitalTools,
      'sharesContent': sharesContent,
      'children': children.map((child) => child.toMap()).toList(),
    };
  }

  String get fullName {
    final first = firstName?.trim() ?? '';
    final last = surName?.trim() ?? '';
    final name = '$first $last'.trim();
    return name.isEmpty ? 'User' : name;
  }

  bool get hasCompletedOnboarding => role != UserRole.none;
}

List<String> _readStringList(dynamic value) {
  return (value as List<dynamic>? ?? const []).whereType<String>().toList();
}

UserRole _readRole(String? value) {
  return UserRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => UserRole.none,
  );
}
