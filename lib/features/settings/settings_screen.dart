import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/misc_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../routes/app_router.dart';
import '../../services/wallpaper_service.dart';

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
                onTap: () => context.pop(),
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
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${settings.lifespan} yrs',
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: AppColors.accent),
                            ],
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
                      // Wallpaper screen location
                      SettingsRow(
                        label: 'Wallpaper screen',
                        trailing: GestureDetector(
                          onTap: () => _showWallpaperLocationDialog(
                              context, ref, settings.wallpaperLocation),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _wallpaperLocationLabel(
                                    settings.wallpaperLocation),
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: AppColors.accent),
                            ],
                          ),
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
                        trailing: GestureDetector(
                          onTap: () => context.push(AppRoutes.lifeInput),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Edit',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded,
                                  size: 14, color: AppColors.accent),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24), // Spacing for new section
                      const Text(
                        'LEGAL & ABOUT',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Privacy Policy
                      SettingsRow(
                        label: 'Privacy Policy',
                        trailing: GestureDetector(
                          onTap: () => context.push(AppRoutes.privacy),
                          child: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.textMuted),
                        ),
                      ),
                      // Terms of Service
                      SettingsRow(
                        label: 'Terms of Service',
                        showBorder: false,
                        trailing: GestureDetector(
                          onTap: () => context.push(AppRoutes.terms),
                          child: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 14, color: AppColors.textMuted),
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

  String _wallpaperLocationLabel(int location) {
    switch (location) {
      case WallpaperService.locationHomeScreen:
        return 'Home Screen';
      case WallpaperService.locationLockScreen:
        return 'Lock Screen';
      case WallpaperService.locationBothScreens:
      default:
        return 'Both';
    }
  }

  void _showWallpaperLocationDialog(
      BuildContext context, WidgetRef ref, int current) {
    final options = [
      (WallpaperService.locationHomeScreen, 'Home Screen'),
      (WallpaperService.locationLockScreen, 'Lock Screen'),
      (WallpaperService.locationBothScreens, 'Both Screens'),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) {
          int selected = current;
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Update wallpaper on',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose which screen DotDays auto-updates.\nOther screen keeps your gallery wallpaper.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) => GestureDetector(
                      onTap: () => setInner(() => selected = opt.$1),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: selected == opt.$1
                                    ? AppColors.accent
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected == opt.$1
                                      ? AppColors.accent
                                      : AppColors.textMuted,
                                  width: 1.5,
                                ),
                              ),
                              child: selected == opt.$1
                                  ? const Icon(Icons.check,
                                      size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              opt.$2,
                              style: TextStyle(
                                color: selected == opt.$1
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
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
                      .setWallpaperLocation(selected);
                  if (context.mounted) Navigator.pop(ctx);
                },
                child: const Text('Save',
                    style: TextStyle(color: AppColors.accent)),
              ),
            ],
          );
        },
      ),
    );
  }
}
