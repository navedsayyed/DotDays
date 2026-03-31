import 'dart:io';
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import '../core/constants/app_constants.dart';
import 'storage_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Re-init storage since this runs in a separate isolate
    await StorageService.init();
    debugPrint('BackgroundService: daily update task running');
    // The wallpaper regeneration logic will be triggered on next app open
    // For background-only image updates we'd need a headless render approach
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
      frequency: const Duration(hours: 24),
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
