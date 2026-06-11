import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_logo.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textHeadline,
        elevation: 0,
        title: const Text(
          'About Us',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: AppLogoLockup(logoSize: 56, textSize: 36),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ignite curiosity. Light the future.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'FEMA is a digital learning platform designed to support '
                'Ethiopian students from KG to Grade 12. We connect students, '
                'parents, and educators with high-quality lessons, expert '
                'teachers, and progress-tracking tools, all in one place.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textBody,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _Section(
                title: 'Our Mission',
                body: 'To make quality, locally-relevant education accessible '
                    'and engaging for every Ethiopian learner.',
              ),
              const SizedBox(height: 20),
              _Section(
                title: 'Get in touch',
                body: 'support@fema.app',
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'Version 1.0.0',
                  style: TextStyle(fontSize: 13, color: AppColors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textBody,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
