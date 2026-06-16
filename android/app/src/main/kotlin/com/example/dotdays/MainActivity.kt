package com.example.dotdays

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BATTERY_CHANNEL = "com.example.dotdays/battery"
    private val WALLPAPER_CHANNEL = "com.example.dotdays/wallpaper_id"

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
                    else -> result.notImplemented()
                }
            }

        // Wallpaper ID channel — used in foreground to detect external wallpaper changes
        // and to apply wallpaper with OEM quirk workaround
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLPAPER_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getWallpaperIds" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                            val wm = android.app.WallpaperManager.getInstance(this)
                            val homeId = wm.getWallpaperId(android.app.WallpaperManager.FLAG_SYSTEM)
                            val lockId = wm.getWallpaperId(android.app.WallpaperManager.FLAG_LOCK)
                            result.success(mapOf("home" to homeId, "lock" to lockId))
                        } else {
                            result.success(mapOf("home" to -1, "lock" to -1))
                        }
                    }
                    "saveCurrentIds" -> {
                        WallpaperIdChecker.saveCurrentIds(this)
                        result.success(null)
                    }
                    "computeSmartLocation" -> {
                        val smart = WallpaperIdChecker.computeAndSaveSmartLocation(this)
                        result.success(smart)
                    }
                    "smartSetWallpaper" -> {
                        // OEM-aware wallpaper setter that preserves the other screen
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
}
