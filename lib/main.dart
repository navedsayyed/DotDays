import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'services/wallpaper_auto_updater.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await StorageService.init();
  await BackgroundService.init();

  // Auto-update wallpaper if day changed (fallback for background task)
  WallpaperAutoUpdater.checkAndUpdate();

  runApp(const ProviderScope(child: LifeInDotsApp()));
}

class LifeInDotsApp extends ConsumerWidget {
  const LifeInDotsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Life in Dots',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
