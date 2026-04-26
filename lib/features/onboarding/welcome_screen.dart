import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/misc_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),
              // Orb + Title
              const Column(
                children: [
                  AccentOrb(size: 48),
                  SizedBox(height: 24),
                  Text(
                    'Every dot is\na day of\nyour life.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'See how many days you\'ve lived —\nand how many remain.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Buttons
              PrimaryButton(
                label: 'Get Started →',
                onPressed: () => context.push(AppRoutes.chooseType),
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Learn More',
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => const _LearnMoreSheet(),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnMoreSheet extends StatelessWidget {
  const _LearnMoreSheet();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Life in Dots',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'This app visualizes your life as a grid of dots — each dot represents one day. '
            'See how many days you\'ve lived and how many remain. '
            'Set it as your wallpaper to stay mindful every single day.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.6),
          ),
          SizedBox(height: 20),
          Text(
            '🔒 All data stays on your device.\n📱 Auto-updates every day.\n🎯 Track life, year, and goals.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.8),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
