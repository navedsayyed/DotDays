import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Calendar type
  static String? getCalendarType() => _prefs.getString(AppConstants.keyCalendarType);
  static Future<void> setCalendarType(String type) =>
      _prefs.setString(AppConstants.keyCalendarType, type);

  // Date of birth
  static DateTime? getDateOfBirth() {
    final ms = _prefs.getInt(AppConstants.keyDateOfBirth);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  static Future<void> setDateOfBirth(DateTime dob) =>
      _prefs.setInt(AppConstants.keyDateOfBirth, dob.millisecondsSinceEpoch);

  // Lifespan
  static int getLifespan() =>
      _prefs.getInt(AppConstants.keyLifespan) ?? AppConstants.defaultLifespan;
  static Future<void> setLifespan(int years) =>
      _prefs.setInt(AppConstants.keyLifespan, years);

  // Goal
  static String? getGoalName() => _prefs.getString(AppConstants.keyGoalName);
  static Future<void> setGoalName(String name) =>
      _prefs.setString(AppConstants.keyGoalName, name);

  static DateTime? getGoalStart() {
    final ms = _prefs.getInt(AppConstants.keyGoalStart);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  static Future<void> setGoalStart(DateTime date) =>
      _prefs.setInt(AppConstants.keyGoalStart, date.millisecondsSinceEpoch);

  static DateTime? getGoalEnd() {
    final ms = _prefs.getInt(AppConstants.keyGoalEnd);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }
  static Future<void> setGoalEnd(DateTime date) =>
      _prefs.setInt(AppConstants.keyGoalEnd, date.millisecondsSinceEpoch);

  // Settings
  static bool getAutoUpdate() =>
      _prefs.getBool(AppConstants.keyAutoUpdate) ?? true;
  static Future<void> setAutoUpdate(bool val) =>
      _prefs.setBool(AppConstants.keyAutoUpdate, val);

  static bool getLockScreen() =>
      _prefs.getBool(AppConstants.keyLockScreen) ?? true;
  static Future<void> setLockScreen(bool val) =>
      _prefs.setBool(AppConstants.keyLockScreen, val);

  static bool getShowDayCounter() =>
      _prefs.getBool(AppConstants.keyShowDayCounter) ?? false;
  static Future<void> setShowDayCounter(bool val) =>
      _prefs.setBool(AppConstants.keyShowDayCounter, val);

  static int getLivedDotColor() =>
      _prefs.getInt(AppConstants.keyLivedDotColor) ?? 0xFFFFFFFF;
  static Future<void> setLivedDotColor(int color) =>
      _prefs.setInt(AppConstants.keyLivedDotColor, color);

  static bool getOnboardingComplete() =>
      _prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;
  static Future<void> setOnboardingComplete(bool val) =>
      _prefs.setBool(AppConstants.keyOnboardingComplete, val);

  // Wallpaper location (home=1, lock=2, both=3)
  static int getWallpaperLocation() =>
      _prefs.getInt(AppConstants.keyWallpaperLocation) ?? 3;
  static Future<void> setWallpaperLocation(int location) =>
      _prefs.setInt(AppConstants.keyWallpaperLocation, location);

  // Generic string get/set (for misc keys like last-update-day)
  static String? getString(String key) => _prefs.getString(key);
  static Future<void> setString(String key, String val) =>
      _prefs.setString(key, val);

  // Generic bool get/set (for flags like needs_reschedule)
  static bool? getBool(String key) => _prefs.getBool(key);
  static Future<void> setBool(String key, bool val) =>
      _prefs.setBool(key, val);
}
