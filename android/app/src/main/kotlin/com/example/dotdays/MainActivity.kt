package com.example.dotdays

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BATTERY_CHANNEL = "com.example.dotdays/battery"
    private val WALLPAPER_CHANNEL = "com.example.dotdays/wallpaper_id"

    companion object {
        private const val NOTIFICATION_PERMISSION_CODE = 1001
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Battery optimization channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestIgnoreBatteryOptimization" -> {
                        requestIgnoreBatteryOptimization()
                        result.success(null)
                    }
                    "isIgnoringBatteryOptimization" -> {
                        result.success(isIgnoringBatteryOptimization())
                    }
                    "requestNotificationPermission" -> {
                        requestNotificationPermission()
                        result.success(null)
                    }
                    "hasNotificationPermission" -> {
                        result.success(hasNotificationPermission())
                    }
                    else -> result.notImplemented()
                }
            }

        // Wallpaper channel — OEM-aware wallpaper setter (foreground fallback)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLPAPER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "smartSetWallpaper" -> {
                        val imageBytes = call.argument<ByteArray>("imageBytes")
                        val location = call.argument<Int>("location")
                        if (imageBytes == null || location == null) {
                            result.error("INVALID_ARGS", "imageBytes and location required", null)
                            return@setMethodCallHandler
                        }
                        try {
                            val success = SmartWallpaperSetter.applyWallpaper(this, imageBytes, location)
                            result.success(success)
                        } catch (e: Exception) {
                            result.error("WALLPAPER_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun requestIgnoreBatteryOptimization() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                    data = Uri.parse("package:$packageName")
                }
                startActivity(intent)
            }
        }
    }

    private fun isIgnoringBatteryOptimization(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val pm = getSystemService(POWER_SERVICE) as PowerManager
            return pm.isIgnoringBatteryOptimizations(packageName)
        }
        return true
    }

    private fun requestNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_CODE
                )
            }
        }
        // On Android 12 and below, notifications are allowed by default
    }

    private fun hasNotificationPermission(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        }
        return true // Pre-Android 13 doesn't need runtime permission
    }
}
