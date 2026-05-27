import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'services/battery_optimization_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await StorageService.init();
  await BackgroundService.init();

  // Ensure the periodic background task is scheduled (survives reboots)
  await BackgroundService.ensureScheduled();

  // NOTE: We do NOT call WallpaperAutoUpdater.checkAndUpdate() on startup.
  // Doing so would overwrite any wallpaper the user set from Gallery or
  // another app. The midnight alarm (BackgroundService) handles daily updates.

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
      // NOTE: We intentionally do NOT call WallpaperAutoUpdater.checkAndUpdate()
      // here. Re-applying the wallpaper on every app resume would overwrite any
      // wallpaper the user set from Gallery or another app. The midnight
      // background alarm (BackgroundService) handles the daily dot-update.
      // We only re-ensure the alarm is still scheduled.
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
