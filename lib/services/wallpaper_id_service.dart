import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';
import 'wallpaper_service.dart';

/// Service that uses Android's WallpaperManager.getWallpaperId() to detect
/// whether the user changed the wallpaper externally (e.g. from Gallery).
///
/// Two modes of operation:
/// 1. **Foreground** (app open): Uses method channel to get current IDs,
///    compares with saved IDs, and updates wallpaperLocation in storage.
///    The background service reads this updated location at midnight.
///
/// 2. **Background** (midnight alarm): The native DotDaysApplication.onCreate()
///    runs WallpaperIdChecker before Dart starts, writing the smart location
///    to SharedPreferences. The Dart callback reads it directly.
class WallpaperIdService {
  WallpaperIdService._();

  static const _channel = MethodChannel('com.example.dotdays/wallpaper_id');

  // SharedPreferences keys
  static const String _keyHomeId = 'dotdays_home_wallpaper_id';
  static const String _keyLockId = 'dotdays_lock_wallpaper_id';

  /// Get current wallpaper IDs from the system (foreground only).
  /// Returns {home: int, lock: int}. Returns -1 if unavailable.
  static Future<Map<String, int>> getWallpaperIds() async {
    if (!Platform.isAndroid) return {'home': -1, 'lock': -1};

    try {
      final result = await _channel.invokeMapMethod<String, int>('getWallpaperIds');
      return {
        'home': result?['home'] ?? -1,
        'lock': result?['lock'] ?? -1,
      };
    } catch (e) {
      debugPrint('WallpaperIdService.getWallpaperIds error: $e');
      return {'home': -1, 'lock': -1};
    }
  }

  /// Save the current wallpaper IDs after DotDays applies a wallpaper.
  /// Call this right after successfully applying the wallpaper.
  /// Works in foreground via method channel.
  static Future<void> saveCurrentIds() async {
    if (!Platform.isAndroid) return;

    try {
      // Use the native method which also clears the stale flag
      await _channel.invokeMethod('saveCurrentIds');
      debugPrint('WallpaperIdService: saved IDs via native');
    } catch (e) {
      // Fallback: save from Dart if method channel not available
      debugPrint('WallpaperIdService: native save failed ($e), saving from Dart');
      final ids = await getWallpaperIds();
      final homeId = ids['home'] ?? -1;
      final lockId = ids['lock'] ?? -1;
      await StorageService.setString(_keyHomeId, homeId.toString());
      await StorageService.setString(_keyLockId, lockId.toString());
      debugPrint('WallpaperIdService: saved IDs from Dart — home=$homeId, lock=$lockId');
    }
  }

  /// Detect if the user changed wallpaper externally and update
  /// wallpaperLocation accordingly. Call this in the FOREGROUND
  /// (on app start and resume) where method channels work.
  ///
  /// This is the key method that makes the automatic detection work:
  /// - Gets current system wallpaper IDs
  /// - Compares with saved IDs from when DotDays last applied
  /// - If user changed home screen → updates wallpaperLocation to lock-only
  /// - If user changed lock screen → updates wallpaperLocation to home-only
  /// - If user changed both → updates wallpaperLocation to skip (-1 won't be saved,
  ///   but we can disable auto-update or notify)
  static Future<void> detectAndUpdateLocation() async {
    if (!Platform.isAndroid) return;

    final ids = await getWallpaperIds();
    final currentHome = ids['home'] ?? -1;
    final currentLock = ids['lock'] ?? -1;

    // If we can't read IDs, skip detection
    if (currentHome == -1 && currentLock == -1) {
      debugPrint('WallpaperIdService: IDs unavailable, skipping detection');
      return;
    }

    final savedHomeStr = StorageService.getString(_keyHomeId);
    final savedLockStr = StorageService.getString(_keyLockId);

    // If no saved IDs (first run), save current as baseline and return
    if (savedHomeStr == null && savedLockStr == null) {
      debugPrint('WallpaperIdService: no saved IDs, saving baseline');
      await StorageService.setString(_keyHomeId, currentHome.toString());
      await StorageService.setString(_keyLockId, currentLock.toString());
      return;
    }

    final savedHome = int.tryParse(savedHomeStr ?? '') ?? -1;
    final savedLock = int.tryParse(savedLockStr ?? '') ?? -1;

    final homeMatches = savedHome != -1 && currentHome == savedHome;
    final lockMatches = savedLock != -1 && currentLock == savedLock;

    // When wallpaper is set to "both", Android may return -1 for lock ID
    // (no separate lock screen wallpaper — it mirrors home)
    final lockWasMirrored = savedLock == -1 && currentLock == -1;
    final effectiveLockMatches = lockMatches || (lockWasMirrored && homeMatches);

    final originalLocation = StorageService.getWallpaperLocation();

    debugPrint('WallpaperIdService: detecting changes — '
        'home=$currentHome(saved=$savedHome, match=$homeMatches) '
        'lock=$currentLock(saved=$savedLock, match=$effectiveLockMatches) '
        'originalLocation=$originalLocation');

    // If both match, no external changes — nothing to do
    if (homeMatches && effectiveLockMatches) {
      debugPrint('WallpaperIdService: no external changes detected');
      return;
    }

    // Determine new wallpaper location based on what still matches
    int newLocation;
    switch (originalLocation) {
      case WallpaperService.locationBothScreens:
        if (homeMatches && !effectiveLockMatches) {
          newLocation = WallpaperService.locationHomeScreen;
          debugPrint('WallpaperIdService: user changed LOCK screen → updating to home-only');
        } else if (!homeMatches && effectiveLockMatches) {
          newLocation = WallpaperService.locationLockScreen;
          debugPrint('WallpaperIdService: user changed HOME screen → updating to lock-only');
        } else {
          // Both changed — disable auto-update for now
          debugPrint('WallpaperIdService: user changed BOTH screens');
          // Don't change location to -1, just leave it. User can re-apply from app.
          return;
        }
        break;

      case WallpaperService.locationHomeScreen:
        if (!homeMatches) {
          debugPrint('WallpaperIdService: user changed home screen (was home-only)');
          return; // Can't update anywhere, leave as is
        }
        return; // Still matches, nothing to do

      case WallpaperService.locationLockScreen:
        if (!effectiveLockMatches) {
          debugPrint('WallpaperIdService: user changed lock screen (was lock-only)');
          return; // Can't update anywhere, leave as is
        }
        return; // Still matches, nothing to do

      default:
        return;
    }

    // Update the wallpaper location in storage so background service uses it
    await StorageService.setWallpaperLocation(newLocation);
    debugPrint('WallpaperIdService: wallpaperLocation updated to $newLocation');

    // Save current IDs as new baseline
    await StorageService.setString(_keyHomeId, currentHome.toString());
    await StorageService.setString(_keyLockId, currentLock.toString());
  }
}
