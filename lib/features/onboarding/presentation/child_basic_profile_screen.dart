import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
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
  final _dateController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dateController.dispose();
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
      backgroundColor: Colors.white,
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
                style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Help us personalize the experience by setting up a student account for your child.",
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              const _FormLabel(label: "Full Name"),
              AppTextField(
                controller: _fullNameController,
                hintText: 'e.g. Kidus Abebe',
                validator: (value) => value == null || value.isEmpty ? 'Required' : null,
              ),
              
              const SizedBox(height: 24),
              const _FormLabel(label: "Gender"),
              Row(
                children: [
                  Expanded(
                    child: _GenderToggle(
                      label: 'Male',
                      icon: Icons.male,
                      isSelected: _selectedGender == 'Male',
                      onTap: () => setState(() => _selectedGender = 'Male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _GenderToggle(
                      label: 'Female',
                      icon: Icons.female,
                      isSelected: _selectedGender == 'Female',
                      onTap: () => setState(() => _selectedGender = 'Female'),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              const _FormLabel(label: "Birth Date"),
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 365 * 10)),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedBirthDate = pickedDate;
                      _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
                    });
                  }
                },
                child: AbsorbPointer(
                  child: AppTextField(
                    controller: _dateController,
                    hintText: 'Select date...',
                    prefixIcon: const Icon(Icons.calendar_today_outlined),
                  ),
                ),
              ),
              
              const SizedBox(height: 48),
              AppButton(
                text: 'Continue',
                onPressed: _onContinue,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  final String label;
  const _FormLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.textHeadline),
      ),
    );
  }
}

class _GenderToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderToggle({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.greyLight, width: isSelected ? 2 : 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textHeadline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
