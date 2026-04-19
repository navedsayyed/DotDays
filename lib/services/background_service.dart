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

      final autoUpdate = StorageService.getAutoUpdate();
      if (!autoUpdate) return Future.value(true);

      final onboardingDone = StorageService.getOnboardingComplete();
      if (!onboardingDone) return Future.value(true);

      // Check if already updated today
      final now = DateTime.now();
      final todayKey = '${now.year}-${now.month}-${now.day}';
      final lastUpdate = StorageService.getString('wallpaper_last_update_day');
      if (lastUpdate == todayKey) {
        debugPrint('BackgroundService: already updated today, skipping');
        return Future.value(true);
      }

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
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

  /// Schedule the periodic wallpaper update task.
  /// Runs every 15 minutes (Android's minimum interval for WorkManager).
  /// The task itself checks if the day has changed before doing any work.
  /// No initialDelay — we want the first run ASAP after scheduling.
  static Future<void> scheduleDaily() async {
    if (!Platform.isAndroid) return;
    await Workmanager().registerPeriodicTask(
      AppConstants.workerUniqueName,
      AppConstants.workerTaskName,
      frequency: const Duration(minutes: 15),
      // NO initialDelay — run the first check immediately
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      // Keep existing task instead of replacing, so reboots don't reset timing
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
    debugPrint('BackgroundService: periodic task scheduled (every 15 min)');
  }

  /// Re-schedule the task — useful on app launch to ensure it's still alive.
  /// Uses KEEP policy so it doesn't interfere if already scheduled.
  static Future<void> ensureScheduled() async {
    if (!Platform.isAndroid) return;
    final autoUpdate = StorageService.getAutoUpdate();
    final onboardingDone = StorageService.getOnboardingComplete();
    if (autoUpdate && onboardingDone) {
      await scheduleDaily();
    }
  }

  static Future<void> cancel() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelByUniqueName(AppConstants.workerUniqueName);
  }
}
