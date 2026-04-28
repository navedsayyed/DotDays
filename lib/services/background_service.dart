import 'dart:io';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../core/constants/app_constants.dart';
import '../shared/models/calendar_type.dart';
import 'storage_service.dart';
import 'headless_wallpaper_renderer.dart';
import 'wallpaper_service.dart';

@pragma('vm:entry-point')
void alarmCallbackDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Re-init storage since this runs in a separate isolate
    await StorageService.init();

    final autoUpdate = StorageService.getAutoUpdate();
    if (!autoUpdate) return;

    final onboardingDone = StorageService.getOnboardingComplete();
    if (!onboardingDone) return;

    // Check if already updated today
    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final lastUpdate = StorageService.getString('wallpaper_last_update_day');
    if (lastUpdate == todayKey) {
      debugPrint('BackgroundService: already updated today, skipping');
      return;
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
  } finally {
    // Always schedule next day's alarm so it creates a daily cycle
    BackgroundService.scheduleDaily();
  }
}

class BackgroundService {
  BackgroundService._();
  
  static const int alarmId = 1001;

  static Future<void> init() async {
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.initialize();
  }

  /// Schedule the wallpaper update for exactly midnight.
  static Future<void> scheduleDaily() async {
    if (!Platform.isAndroid) return;
    final now = DateTime.now();
    
    // Calculate the next midnight (plus 5 seconds to ensure the day has fully rolled over)
    DateTime nextMidnight = DateTime(now.year, now.month, now.day + 1, 0, 0, 5);
    
    // Use oneShotAt for exact timing and wakeup
    await AndroidAlarmManager.oneShotAt(
      nextMidnight,
      alarmId,
      alarmCallbackDispatcher,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
    debugPrint('BackgroundService: exact alarm scheduled for $nextMidnight');
  }

  /// Re-schedule the task — useful on app launch to ensure it's still alive.
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
    await AndroidAlarmManager.cancel(alarmId);
  }
}
