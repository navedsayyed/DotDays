import 'dart:io';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../core/constants/app_constants.dart';
import '../shared/models/calendar_type.dart';
import 'storage_service.dart';
import 'headless_wallpaper_renderer.dart';
import 'wallpaper_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Re-init storage since this runs in a separate isolate
      await StorageService.init();
      debugPrint('BackgroundService: daily wallpaper update starting');

      // Read settings from storage
      final calTypeStr = StorageService.getCalendarType();
      final calendarType = calTypeStr != null
          ? CalendarType.fromKey(calTypeStr)
          : CalendarType.life;
      final dob = StorageService.getDateOfBirth();
      final lifespan = StorageService.getLifespan();
      final goalName = StorageService.getGoalName();
      final goalStart = StorageService.getGoalStart();
      final goalEnd = StorageService.getGoalEnd();
      final livedDotColorVal = StorageService.getLivedDotColor();
      final wallpaperLocation = StorageService.getWallpaperLocation();

      // Render new wallpaper with today's date
      final file = await HeadlessWallpaperRenderer.render(
        calendarType: calendarType,
        dateOfBirth: dob,
        lifespan: lifespan,
        goalName: goalName,
        goalStart: goalStart,
        goalEnd: goalEnd,
        livedDotColor: Color(livedDotColorVal),
      );

      if (file != null) {
        // Apply the regenerated wallpaper
        final success =
            await WallpaperService.applyWallpaper(file, wallpaperLocation);
        if (success) {
          // Track last update day so app-launch updater doesn't duplicate
          final now = DateTime.now();
          final todayKey = '${now.year}-${now.month}-${now.day}';
          await StorageService.setString(
              'wallpaper_last_update_day', todayKey);
        }
        debugPrint(
            'BackgroundService: wallpaper applied = $success (location=$wallpaperLocation)');
      } else {
        debugPrint('BackgroundService: failed to render wallpaper');
      }
    } catch (e) {
      debugPrint('BackgroundService error: $e');
    }
    return Future.value(true);
  });
}

class BackgroundService {
  BackgroundService._();

  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> scheduleDaily() async {
    if (!Platform.isAndroid) return;
    await Workmanager().registerPeriodicTask(
      AppConstants.workerUniqueName,
      AppConstants.workerTaskName,
      frequency: const Duration(minutes: 15),
      initialDelay: _timeUntilMidnight(),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
    );
    debugPrint('BackgroundService: daily task scheduled');
  }

  static Future<void> cancel() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelByUniqueName(AppConstants.workerUniqueName);
  }

  static Duration _timeUntilMidnight() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }
}
