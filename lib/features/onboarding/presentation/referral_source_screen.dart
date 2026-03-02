import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../domain/onboarding_provider.dart';
import 'widgets/onboarding_progress_header.dart';

class ReferralSourceScreen extends ConsumerStatefulWidget {
  const ReferralSourceScreen({super.key});

  @override
  ConsumerState<ReferralSourceScreen> createState() => _ReferralSourceScreenState();
}

class _ReferralSourceScreenState extends ConsumerState<ReferralSourceScreen> {
  final List<String> sources = [
    'Social Media (Facebook, TikTok, etc.)',
    'Friends or Family',
    'Search Engine (Google)',
    'TV or Radio Advertisement',
    'School or Teacher',
    'Billboard or Poster',
    'Other'
  ];
  
  String? selectedSource;
  final _otherController = TextEditingController();

  void _onContinue() {
    if (selectedSource == null) return;
    
    if (selectedSource == 'Other' && _otherController.text.isEmpty) return;

    ref.read(onboardingProvider.notifier).setReferralSource(
      selectedSource!,
      selectedSource == 'Other' ? _otherController.text : null,
    );
    
    final role = ref.read(onboardingProvider).role;
    if (role == UserRole.parent) {
      context.push('/onboarding/intro');
    } else {
      context.push('/onboarding/quiz-intro');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OnboardingProgressHeader(
        currentStep: 6,
        totalSteps: 7,
        onSkip: () => context.push('/onboarding/intro'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppConstants.space24),
        child: Column(
          children: [
            const SizedBox(height: AppConstants.space24),
            Text(
              "Where Did You Hear About FEMA?",
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.space32),
            Expanded(
              child: ListView.separated(
                itemCount: sources.length,
                separatorBuilder: (_, __) => const SizedBox(height: AppConstants.space12),
                itemBuilder: (context, index) {
                  final source = sources[index];
                  final isSelected = selectedSource == source;
                  
                  return Column(
                    children: [
                      ListTile(
                        onTap: () => setState(() => selectedSource = source),
                        title: Text(source, style: AppTextStyles.bodyLarge),
                        leading: Radio<String>(
                          value: source,
                          groupValue: selectedSource,
                          onChanged: (val) => setState(() => selectedSource = val),
                          activeColor: AppColors.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.radius12),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.greyLight,
                          ),
                        ),
                        tileColor: Colors.white,
                      ),
                      if (isSelected && source == 'Other') ...[
                        const SizedBox(height: AppConstants.space12),
                        AppTextField(
                          controller: _otherController,
                          hintText: 'Please specify',
                          autofocus: true,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: AppConstants.space24),
            AppButton(
              text: 'Continue',
              onPressed: selectedSource != null ? _onContinue : () {},
              backgroundColor: selectedSource != null ? AppColors.primary : AppColors.greyLight,
            ),
            const SizedBox(height: AppConstants.space32),
          ],
        ),
      ),
    );
  }
}
