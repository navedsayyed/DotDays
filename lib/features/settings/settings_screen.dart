import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/misc_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../routes/app_router.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textMuted, size: 18),
              ),
              const SizedBox(height: 20),
              const Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Lifespan
                      SettingsRow(
                        label: 'Expected lifespan',
                        trailing: GestureDetector(
                          onTap: () =>
                              _showLifespanDialog(context, ref, settings.lifespan),
                          child: Text(
                            '${settings.lifespan} yrs →',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      // Lived dot color
                      SettingsRow(
                        label: 'Dot color (lived)',
                        trailing: DotColorSelector(
                          selectedColor: settings.livedDotColor,
                          colors: AppColors.livedDotColors,
                          onSelect: (c) => notifier.setLivedDotColor(c),
                        ),
                      ),
                      // Today dot (display only)
                      SettingsRow(
                        label: 'Today dot color',
                        trailing: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      // Auto-update
                      SettingsRow(
                        label: 'Auto-update wallpaper',
                        trailing: AppToggle(
                          value: settings.autoUpdate,
                          onChanged: (v) => notifier.setAutoUpdate(v),
                        ),
                      ),
                      // Lock screen
                      SettingsRow(
                        label: 'Show on lock screen',
                        trailing: AppToggle(
                          value: settings.lockScreen,
                          onChanged: (v) => notifier.setLockScreen(v),
                        ),
                      ),
                      // Day counter
                      SettingsRow(
                        label: 'Show day counter',
                        trailing: AppToggle(
                          value: settings.showDayCounter,
                          onChanged: (v) => notifier.setShowDayCounter(v),
                        ),
                      ),
                      // Date of birth
                      SettingsRow(
                        label: 'Date of birth',
                        showBorder: false,
                        trailing: GestureDetector(
                          onTap: () => context.go(AppRoutes.lifeInput),
                          child: const Text(
                            'Edit →',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer
              const Padding(
                padding: EdgeInsets.only(bottom: 24, top: 8),
                child: Text(
                  '${AppConstants.appName} · v${AppConstants.appVersion} · All data on device',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLifespanDialog(
      BuildContext context, WidgetRef ref, int current) {
    int temp = current;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Expected Lifespan',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.accent),
                onPressed: () {
                  if (temp > 50) setInner(() => temp--);
                },
              ),
              Text(
                '$temp years',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: AppColors.accent),
                onPressed: () {
                  if (temp < 120) setInner(() => temp++);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(appSettingsProvider.notifier)
                    .setLifespan(temp);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );
  }
}
