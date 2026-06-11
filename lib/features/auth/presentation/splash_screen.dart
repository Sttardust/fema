import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            AppLogo(size: 96),
            SizedBox(height: 24),
            Text(
              'Fema',
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -1.5,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Ignite Curiosity.',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Light the Future.',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
