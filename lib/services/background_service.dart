import 'dart:io';
import 'package:flutter/material.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../shared/models/calendar_type.dart';
import 'storage_service.dart';
import 'headless_wallpaper_renderer.dart';
import 'wallpaper_service.dart';

/// Background alarm callback — runs at midnight.
///
/// Decision tree (following the reference app's proven approach):
///   Read: auto_update_home, auto_update_lock
///   If auto_update_home → apply to home (FLAG=1)
///   If auto_update_lock → apply to lock (FLAG=2)
///
/// No detection of external changes. No smart location.
/// The user controls which screens auto-update via Settings toggles.
@pragma('vm:entry-point')
void alarmCallbackDispatcher() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Re-init storage since this runs in a separate isolate
    await StorageService.init();
    await StorageService.reload();

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

    // Read per-screen auto-update flags
    final autoHome = StorageService.getAutoUpdateHome();
    final autoLock = StorageService.getAutoUpdateLock();

    if (!autoHome && !autoLock) {
      debugPrint('BackgroundService: both screens disabled, skipping');
      await StorageService.setString('wallpaper_last_update_day', todayKey);
      return;
    }

    debugPrint('BackgroundService: daily update starting (home=$autoHome, lock=$autoLock)');

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

    // Render new wallpaper with today's date (render once, apply to each screen)
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
      bool anySuccess = false;

      // Apply to each screen independently (like the reference app does)
      // Uses SmartWallpaperSetter which handles OEM quirks (save/restore other screen)
      if (autoHome) {
        final ok = await WallpaperService.applyWallpaper(
          file, WallpaperService.locationHomeScreen,
        );
        debugPrint('BackgroundService: home screen ${ok ? "✓" : "✗"}');
        anySuccess = anySuccess || ok;
      }

      if (autoLock) {
        final ok = await WallpaperService.applyWallpaper(
          file, WallpaperService.locationLockScreen,
        );
        debugPrint('BackgroundService: lock screen ${ok ? "✓" : "✗"}');
        anySuccess = anySuccess || ok;
      }

      if (anySuccess) {
        await StorageService.setString('wallpaper_last_update_day', todayKey);
        debugPrint('BackgroundService: wallpaper applied successfully');
      } else {
        debugPrint('BackgroundService: failed to apply wallpaper');
      }
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
