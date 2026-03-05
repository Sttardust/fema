import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class ChildBasicProfileScreen extends ConsumerStatefulWidget {
  const ChildBasicProfileScreen({super.key});

  @override
  ConsumerState<ChildBasicProfileScreen> createState() => _ChildBasicProfileScreenState();
}

class _ChildBasicProfileScreenState extends ConsumerState<ChildBasicProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  void _onContinue() {
    if (_formKey.currentState!.validate()) {
      final currentChild = ref.read(onboardingProvider).activeChild ?? ChildProfile();
      ref.read(onboardingProvider.notifier).updateActiveChild(
            currentChild.copyWith(
              fullName: _fullNameController.text,
              gender: _selectedGender,
              birthDate: _selectedBirthDate,
            ),
          );
      context.push('/onboarding/grade');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: 3,
        totalSteps: 8,
        showSkip: true,
        onSkip: () => context.go('/home'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.space32),
              Text(
                "Create Your Child’s Learning Profile",
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space16),
              Text(
                "Help us personalize the experience by setting up a student account for your child.",
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space32),
              Text("Full Name *", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(hintText: 'temesgen'),
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: AppConstants.space20),
              Text("Gender", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: ['Male', 'Female', 'Other']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
                decoration: const InputDecoration(hintText: 'Gender'),
              ),
              const SizedBox(height: AppConstants.space20),
              Text("Birth Date", style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              TextFormField(
                readOnly: true,
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedBirthDate = pickedDate;
                    });
                  }
                },
                decoration: InputDecoration(
                  hintText: _selectedBirthDate == null
                      ? 'Select...'
                      : DateFormat('yyyy-MM-dd').format(_selectedBirthDate!),
                ),
              ),
              const SizedBox(height: AppConstants.space48),
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
