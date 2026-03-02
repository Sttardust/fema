import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';

class FemaIntroScreen extends ConsumerWidget {
  const FemaIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.space24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppConstants.space24),
              Text(
                "Welcome to the FEMA Family!",
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.space24),
              // Video Placeholder
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(AppConstants.radius16),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill, color: Colors.white, size: 64),
                      SizedBox(height: 8),
                      Text('Introduction Video', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppConstants.space32),
              Text(
                "Everything you need to succeed:",
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppConstants.space16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: AppConstants.space16,
                mainAxisSpacing: AppConstants.space16,
                childAspectRatio: 1.2,
                children: const [
                  _FeatureTile(
                    icon: Icons.auto_awesome_outlined,
                    title: "Adaptive Learning",
                    color: Colors.blue,
                  ),
                  _FeatureTile(
                    icon: Icons.person_search_outlined,
                    title: "Expert Teachers",
                    color: Colors.green,
                  ),
                  _FeatureTile(
                    icon: Icons.analytics_outlined,
                    title: "Track Progress",
                    color: Colors.orange,
                  ),
                  _FeatureTile(
                    icon: Icons.groups_outlined,
                    title: "Community",
                    color: Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.space40),
              AppButton(
                text: "Let's Get Started!",
                onPressed: () async {
                  await ref.read(onboardingProvider.notifier).completeOnboarding();
                  if (context.mounted) {
                    context.go('/home');
                  }
                },
              ),
              const SizedBox(height: AppConstants.space32),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.space16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppConstants.radius16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
