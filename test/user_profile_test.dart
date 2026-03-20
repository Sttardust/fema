import 'package:flutter_test/flutter_test.dart';
import 'package:fema/features/onboarding/domain/onboarding_provider.dart';
import 'package:fema/features/profile/domain/user_profile.dart';

void main() {
  test('AppUserProfile parses firestore payload into typed fields', () {
    final profile = AppUserProfile.fromMap('uid-123', {
      'role': 'parent',
      'firstName': 'Abebe',
      'surName': 'Kebede',
      'children': [
        {
          'fullName': 'Kidus Abebe',
          'username': 'kidus2015',
          'grade': 'Grade 4',
          'birthDate': '2015-01-02T00:00:00.000',
        },
      ],
    });

    expect(profile.uid, 'uid-123');
    expect(profile.role, UserRole.parent);
    expect(profile.fullName, 'Abebe Kebede');
    expect(profile.children, hasLength(1));
    expect(profile.children.first.username, 'kidus2015');
    expect(profile.children.first.birthDate, DateTime(2015, 1, 2));
  });

  test('AppUserProfile builds serializable map from onboarding state', () {
    final profile = AppUserProfile.fromOnboarding(
      'uid-456',
      OnboardingState(
        role: UserRole.teacher,
        firstName: 'Hana',
        surName: 'Tesfaye',
        teachingSubjects: const ['science'],
      ),
    );

    expect(profile.role, UserRole.teacher);
    expect(profile.toMap()['role'], 'teacher');
    expect(profile.toMap()['teachingSubjects'], ['science']);
  });
}
