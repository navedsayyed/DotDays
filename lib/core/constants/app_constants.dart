/// App-wide constants for Life in Dots
class AppConstants {
  AppConstants._();

  static const String appName = 'Life in Dots';
  static const String appVersion = '1.0.0';

  // Default values
  static const int defaultLifespan = 80;
  static const int daysInYear = 365;

  // Wallpaper safe area (as percentage of total height)
  static const double wallpaperTopSafePercent = 0.28;
  static const double wallpaperBottomSafePercent = 0.18;

  // WorkManager task name
  static const String workerTaskName = 'life_in_dots_daily_update';
  static const String workerUniqueName = 'life_in_dots_unique';

  // SharedPreferences keys
  static const String keyCalendarType = 'calendar_type';
  static const String keyDateOfBirth = 'date_of_birth';
  static const String keyLifespan = 'lifespan';
  static const String keyGoalName = 'goal_name';
  static const String keyGoalStart = 'goal_start';
  static const String keyGoalEnd = 'goal_end';
  static const String keyAutoUpdate = 'auto_update';
  static const String keyLockScreen = 'lock_screen';
  static const String keyShowDayCounter = 'show_day_counter';
  static const String keyLivedDotColor = 'lived_dot_color';
  static const String keyOnboardingComplete = 'onboarding_complete';
}
