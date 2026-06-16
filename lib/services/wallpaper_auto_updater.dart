import 'dart:io';
import 'package:flutter/material.dart';
import '../shared/models/calendar_type.dart';
import 'storage_service.dart';
import 'headless_wallpaper_renderer.dart';
import 'wallpaper_service.dart';
import 'wallpaper_id_service.dart';

/// Service that checks on app launch whether the wallpaper needs updating
/// (i.e., day has changed since last update) and regenerates + reapplies it.
///
/// This runs in the FOREGROUND, so method channels work here.
/// The foreground detection in main.dart already updates wallpaperLocation
/// before this is called, so we can just read the stored location.
class WallpaperAutoUpdater {
  WallpaperAutoUpdater._();

  static const String _keyLastUpdateDay = 'wallpaper_last_update_day';

  /// Call this on app start (after StorageService.init).
  /// If autoUpdate is on and the day has changed, re-render & apply wallpaper.
  static Future<void> checkAndUpdate() async {
    if (!Platform.isAndroid) return;

    final autoUpdate = StorageService.getAutoUpdate();
    if (!autoUpdate) return;

    final onboardingDone = StorageService.getOnboardingComplete();
    if (!onboardingDone) return;

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final lastUpdate = StorageService.getString(_keyLastUpdateDay);

    if (lastUpdate == todayKey) {
      debugPrint('WallpaperAutoUpdater: already updated today');
      return;
    }

    debugPrint('WallpaperAutoUpdater: day changed, regenerating wallpaper...');

    try {
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

      // wallpaperLocation was already updated by detectAndUpdateLocation()
      // in main.dart before this runs, so it reflects any external changes.
      final wallpaperLocation = StorageService.getWallpaperLocation();

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
        final success =
            await WallpaperService.applyWallpaper(file, wallpaperLocation);
        if (success) {
          await StorageService.setString(_keyLastUpdateDay, todayKey);
          // Save new IDs since we're in the foreground (method channel works)
          await WallpaperIdService.saveCurrentIds();
          debugPrint('WallpaperAutoUpdater: wallpaper updated for $todayKey (location=$wallpaperLocation)');
        }
      }
    } catch (e) {
      debugPrint('WallpaperAutoUpdater error: $e');
    }
  }
}
