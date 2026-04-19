import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service to request battery optimization exemption on Android.
/// Without this exemption, the OS will kill the background wallpaper task.
class BatteryOptimizationService {
  BatteryOptimizationService._();

  static const _channel = MethodChannel('com.example.dotdays/battery');

  /// Request the system to ignore battery optimizations for this app.
  /// This opens the system settings dialog asking the user to allow
  /// unrestricted background activity.
  static Future<void> requestIgnoreBatteryOptimization() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod('requestIgnoreBatteryOptimization');
    } catch (e) {
      debugPrint('BatteryOptimization request error: $e');
    }
  }

  /// Check if the app is already exempted from battery optimization.
  static Future<bool> isIgnoringBatteryOptimization() async {
    if (!Platform.isAndroid) return true;
    try {
      final result =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimization');
      return result ?? false;
    } catch (e) {
      debugPrint('BatteryOptimization check error: $e');
      return false;
    }
  }
}
