import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'services/wallpaper_auto_updater.dart';
import 'services/battery_optimization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await StorageService.init();
  await BackgroundService.init();

  // Ensure the periodic background task is scheduled (survives reboots)
  await BackgroundService.ensureScheduled();

  // Auto-update wallpaper if day changed (immediate fallback for background task)
  WallpaperAutoUpdater.checkAndUpdate();

  // Request battery optimization exemption so Android doesn't kill the task
  _requestBatteryOptimizationIfNeeded();

  runApp(const ProviderScope(child: LifeInDotsApp()));
}

/// Request battery optimization exemption on first run after onboarding.
/// This is critical for Xiaomi, Realme, Samsung, etc. that aggressively
/// kill background tasks.
Future<void> _requestBatteryOptimizationIfNeeded() async {
  final onboardingDone = StorageService.getOnboardingComplete();
  if (!onboardingDone) return;

  final isExempt =
      await BatteryOptimizationService.isIgnoringBatteryOptimization();
  if (!isExempt) {
    await BatteryOptimizationService.requestIgnoreBatteryOptimization();
  }
}

class LifeInDotsApp extends ConsumerWidget {
  const LifeInDotsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DotDays',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
