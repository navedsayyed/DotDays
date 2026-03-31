import 'package:flutter/material.dart';
import 'calendar_type.dart';

class AppSettings {
  final CalendarType calendarType;
  final DateTime? dateOfBirth;
  final int lifespan;
  final String? goalName;
  final DateTime? goalStart;
  final DateTime? goalEnd;
  final bool autoUpdate;
  final bool lockScreen;
  final bool showDayCounter;
  final Color livedDotColor;
  final bool onboardingComplete;

  const AppSettings({
    this.calendarType = CalendarType.life,
    this.dateOfBirth,
    this.lifespan = 80,
    this.goalName,
    this.goalStart,
    this.goalEnd,
    this.autoUpdate = true,
    this.lockScreen = true,
    this.showDayCounter = false,
    this.livedDotColor = const Color(0xFFFFFFFF),
    this.onboardingComplete = false,
  });

  AppSettings copyWith({
    CalendarType? calendarType,
    DateTime? dateOfBirth,
    int? lifespan,
    String? goalName,
    DateTime? goalStart,
    DateTime? goalEnd,
    bool? autoUpdate,
    bool? lockScreen,
    bool? showDayCounter,
    Color? livedDotColor,
    bool? onboardingComplete,
  }) {
    return AppSettings(
      calendarType: calendarType ?? this.calendarType,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      lifespan: lifespan ?? this.lifespan,
      goalName: goalName ?? this.goalName,
      goalStart: goalStart ?? this.goalStart,
      goalEnd: goalEnd ?? this.goalEnd,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      lockScreen: lockScreen ?? this.lockScreen,
      showDayCounter: showDayCounter ?? this.showDayCounter,
      livedDotColor: livedDotColor ?? this.livedDotColor,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}
