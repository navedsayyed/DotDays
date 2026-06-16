import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'services/battery_optimization_service.dart';
import 'services/wallpaper_id_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await StorageService.init();
  await BackgroundService.init();

  // Ensure the periodic background task is scheduled (survives reboots)
  await BackgroundService.ensureScheduled();

  // Detect if the user changed wallpaper externally (e.g. from Gallery).
  // This updates wallpaperLocation so the midnight alarm only applies
  // DotDays to screens where it's still set.
  await _detectWallpaperChanges();

  // Request battery optimization exemption so Android doesn't kill the task
  _requestBatteryOptimizationIfNeeded();

  runApp(const ProviderScope(child: LifeInDotsApp()));
}

/// Detect if the user changed the wallpaper on any screen since DotDays
/// last applied. If so, update the saved IDs so the background service
/// knows which screens to skip.
Future<void> _detectWallpaperChanges() async {
  final onboardingDone = StorageService.getOnboardingComplete();
  if (!onboardingDone) return;

  try {
    // If IDs were marked stale by the background service (it applied a new
    // wallpaper which changes the system IDs), just re-save current IDs
    // as the new baseline — don't compare.
    final idsStale = StorageService.getBool('dotdays_ids_stale') ?? false;
    if (idsStale) {
      debugPrint('WallpaperDetection: IDs stale after background update, refreshing baseline');
      await WallpaperIdService.saveCurrentIds();
      await StorageService.setBool('dotdays_ids_stale', false);
      return;
    }

    // Normal case: compare saved IDs with current system IDs
    // and update wallpaperLocation if user changed a screen externally
    await WallpaperIdService.detectAndUpdateLocation();
  } catch (e) {
    debugPrint('WallpaperDetection error: $e');
  }
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

class LifeInDotsApp extends ConsumerStatefulWidget {
  const LifeInDotsApp({super.key});

  @override
  ConsumerState<LifeInDotsApp> createState() => _LifeInDotsAppState();
}

class _LifeInDotsAppState extends ConsumerState<LifeInDotsApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-detect wallpaper changes every time the app comes to foreground.
      // This catches cases where the user changed wallpaper while the app
      // was in the background (e.g. from Gallery).
      _detectWallpaperChanges();

      // Re-ensure the alarm is still scheduled
      BackgroundService.ensureScheduled();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'DotDays',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
