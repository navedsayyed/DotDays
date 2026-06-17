import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../models/calendar_type.dart';
import '../../services/storage_service.dart';

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  AppSettingsNotifier() : super(const AppSettings()) {
    _loadFromStorage();
  }

  void _loadFromStorage() {
    final calTypeStr = StorageService.getCalendarType();
    final dob = StorageService.getDateOfBirth();
    final lifespan = StorageService.getLifespan();
    final goalName = StorageService.getGoalName();
    final goalStart = StorageService.getGoalStart();
    final goalEnd = StorageService.getGoalEnd();
    final autoUpdate = StorageService.getAutoUpdate();
    final autoUpdateHome = StorageService.getAutoUpdateHome();
    final autoUpdateLock = StorageService.getAutoUpdateLock();
    final lockScreen = StorageService.getLockScreen();
    final showDayCounter = StorageService.getShowDayCounter();
    final livedDotColorVal = StorageService.getLivedDotColor();
    final onboardingComplete = StorageService.getOnboardingComplete();
    final wallpaperLocation = StorageService.getWallpaperLocation();

    state = AppSettings(
      calendarType: calTypeStr != null
          ? CalendarType.fromKey(calTypeStr)
          : CalendarType.life,
      dateOfBirth: dob,
      lifespan: lifespan,
      goalName: goalName,
      goalStart: goalStart,
      goalEnd: goalEnd,
      autoUpdate: autoUpdate,
      autoUpdateHome: autoUpdateHome,
      autoUpdateLock: autoUpdateLock,
      lockScreen: lockScreen,
      showDayCounter: showDayCounter,
      livedDotColor: Color(livedDotColorVal),
      onboardingComplete: onboardingComplete,
      wallpaperLocation: wallpaperLocation,
    );
  }

  Future<void> setCalendarType(CalendarType type) async {
    await StorageService.setCalendarType(type.key);
    state = state.copyWith(calendarType: type);
  }

  Future<void> setDateOfBirth(DateTime dob) async {
    await StorageService.setDateOfBirth(dob);
    state = state.copyWith(dateOfBirth: dob);
  }

  Future<void> setLifespan(int years) async {
    await StorageService.setLifespan(years);
    state = state.copyWith(lifespan: years);
  }

  Future<void> setGoal({
    required String name,
    required DateTime start,
    required DateTime end,
  }) async {
    await StorageService.setGoalName(name);
    await StorageService.setGoalStart(start);
    await StorageService.setGoalEnd(end);
    state = state.copyWith(goalName: name, goalStart: start, goalEnd: end);
  }

  Future<void> setAutoUpdate(bool val) async {
    await StorageService.setAutoUpdate(val);
    state = state.copyWith(autoUpdate: val);
  }

  Future<void> setAutoUpdateHome(bool val) async {
    await StorageService.setAutoUpdateHome(val);
    state = state.copyWith(autoUpdateHome: val);
  }

  Future<void> setAutoUpdateLock(bool val) async {
    await StorageService.setAutoUpdateLock(val);
    state = state.copyWith(autoUpdateLock: val);
  }

  Future<void> setLockScreen(bool val) async {
    await StorageService.setLockScreen(val);
    state = state.copyWith(lockScreen: val);
  }

  Future<void> setShowDayCounter(bool val) async {
    await StorageService.setShowDayCounter(val);
    state = state.copyWith(showDayCounter: val);
  }

  Future<void> setLivedDotColor(Color color) async {
    await StorageService.setLivedDotColor(color.toARGB32());
    state = state.copyWith(livedDotColor: color);
  }

  Future<void> setOnboardingComplete(bool val) async {
    await StorageService.setOnboardingComplete(val);
    state = state.copyWith(onboardingComplete: val);
  }

  Future<void> setWallpaperLocation(int location) async {
    await StorageService.setWallpaperLocation(location);
    state = state.copyWith(wallpaperLocation: location);
  }
}

final appSettingsProvider =
    StateNotifierProvider<AppSettingsNotifier, AppSettings>(
  (ref) => AppSettingsNotifier(),
);
