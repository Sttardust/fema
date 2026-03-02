import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class PersonalDetailsScreen extends ConsumerStatefulWidget {
  const PersonalDetailsScreen({super.key});

  @override
  ConsumerState<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends ConsumerState<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields from state if available
    final state = ref.read(onboardingProvider);
    _firstNameController.text = state.firstName ?? '';
    _surnameController.text = state.surName ?? '';
    _emailController.text = state.email ?? '';
    _phoneController.text = state.phone ?? '';
    _selectedGender = state.gender;
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      ref.read(onboardingProvider.notifier).updatePersonalDetails(
        firstName: _firstNameController.text,
        surName: _surnameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        gender: _selectedGender,
      );
      
      final role = ref.read(onboardingProvider).role;
      if (role == UserRole.teacher) {
        context.push('/onboarding/teacher-personalization');
      } else {
        context.push('/onboarding/school');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingProvider);
    final isPhoneSignup = state.phone != null && state.email == null;

    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: 1,
        totalSteps: 7,
        onSkip: () => context.push('/onboarding/intro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Let's Get to Know Each Other",
                style: AppTextStyles.headlineMedium,
              ),
              const SizedBox(height: AppConstants.space8),
              Text(
                'Tell us a bit about yourself to personalize your profile.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: AppConstants.space32),
              AppTextField(
                controller: _firstNameController,
                hintText: 'Enter your first name',
                labelText: 'First Name*',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppConstants.space20),
              AppTextField(
                controller: _surnameController,
                hintText: 'Enter your surname',
                labelText: 'Surname*',
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppConstants.space20),
              
              if (isPhoneSignup) ...[
                AppTextField(
                  controller: _emailController,
                  hintText: 'example@mail.com',
                  labelText: 'Email Address (Optional)',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppConstants.space20),
                AppTextField(
                  controller: _passwordController,
                  hintText: 'Create a password',
                  labelText: 'Password*',
                  isPassword: true,
                  validator: (val) => val == null || val.length < 6 ? 'Password too short' : null,
                ),
              ] else ...[
                AppTextField(
                  controller: _phoneController,
                  hintText: '912345678',
                  labelText: 'Phone Number (Optional)',
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('+251', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
              
              const SizedBox(height: AppConstants.space20),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: const Text('Select Gender'),
                items: ['Male', 'Female'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (val) => setState(() => _selectedGender = val),
                decoration: InputDecoration(
                  labelText: 'Gender',
                  labelStyle: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppConstants.space40),
              AppButton(
                text: 'Continue',
                onPressed: _onContinue,
              ),
              const SizedBox(height: AppConstants.space32),
            ],
          ),
        ),
      ),
    );
  }
}
