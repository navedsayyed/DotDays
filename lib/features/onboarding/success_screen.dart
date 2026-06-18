import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_router.dart';

class SuccessScreen extends ConsumerStatefulWidget {
  const SuccessScreen({super.key});

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen> {
  static const _batteryChannel = MethodChannel('com.example.dotdays/battery');

  @override
  void initState() {
    super.initState();
    // Request notification permission after the screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestNotificationPermission();
    });
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final hasPermission =
          await _batteryChannel.invokeMethod<bool>('hasNotificationPermission');
      if (hasPermission != true) {
        // Small delay so the success screen is fully visible first
        await Future.delayed(const Duration(milliseconds: 600));
        if (!mounted) return;
        await _batteryChannel.invokeMethod('requestNotificationPermission');
      }
    } catch (e) {
      debugPrint('Notification permission request failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              // Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.border, width: 1.5),
                ),
                child: const Center(
                  child: Text(
                    '✓',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Setup Complete',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Your calendar is saved.\nYou can now preview your dots\nand generate wallpaper anytime.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              // Summary card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _Row('Selected type', settings.calendarType.label),
                    const SizedBox(height: 10),
                    const _Row('Status', 'Ready', valueColor: AppColors.accent),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: '← Back Home',
                onPressed: () => context.go(AppRoutes.home),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _Row(this.label, this.value,
      {this.valueColor = AppColors.textPrimary});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textDim, fontSize: 12)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
