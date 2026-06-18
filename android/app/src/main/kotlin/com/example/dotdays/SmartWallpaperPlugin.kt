package com.example.dotdays

import android.app.WallpaperManager
import android.content.Context
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin that registers the SmartWallpaperSetter method channel
 * on ANY FlutterEngine — including the background engine created by
 * android_alarm_manager_plus.
 *
 * The method channel provides:
 * - smartSetWallpaper: Applies wallpaper with OEM quirk workaround
 * - checkExternalChange: Checks if wallpaper was changed externally
 */
class SmartWallpaperPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "SmartWallpaperPlugin"
        private const val CHANNEL = "com.example.dotdays/smart_wallpaper"
        private const val PREFS_NAME = "FlutterSharedPreferences"
    }

    private lateinit var context: Context
    private lateinit var channel: MethodChannel

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        Log.d(TAG, "Plugin attached to engine")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        Log.d(TAG, "Plugin detached from engine")
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "smartSetWallpaper" -> {
                val imageBytes = call.argument<ByteArray>("imageBytes")
                val location = call.argument<Int>("location")
                if (imageBytes == null || location == null) {
                    result.error("INVALID_ARGS", "imageBytes and location required", null)
                    return
                }
                try {
                    val success = SmartWallpaperSetter.applyWallpaper(context, imageBytes, location)
                    result.success(success)
                } catch (e: Exception) {
                    result.error("WALLPAPER_ERROR", e.message, null)
                }
            }

            "checkExternalChange" -> {
                // Compare saved wallpaper IDs with current IDs
                // Returns: "none", "home", "lock", or "both"
                try {
                    result.success(checkForExternalChange())
                } catch (e: Exception) {
                    Log.e(TAG, "checkExternalChange error: ${e.message}")
                    result.success("none")
                }
            }

            else -> result.notImplemented()
        }
    }

    /**
     * Compare saved wallpaper IDs (from last DotDays apply) with
     * current system wallpaper IDs. If they differ, the user changed
     * the wallpaper externally.
     *
     * Returns: "none", "home", "lock", or "both"
     */
    private fun checkForExternalChange(): String {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return "none"

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val savedHomeId = prefs.getInt("flutter.dotdays_last_home_id", -1)
        val savedLockId = prefs.getInt("flutter.dotdays_last_lock_id", -1)

        val wm = WallpaperManager.getInstance(context)
        val currentHomeId = wm.getWallpaperId(WallpaperManager.FLAG_SYSTEM)
        val currentLockId = wm.getWallpaperId(WallpaperManager.FLAG_LOCK)

        // No saved IDs = first run after code update. Save current IDs
        // as baseline so the NEXT change will be detected.
        if (savedHomeId == -1 && savedLockId == -1) {
            Log.d(TAG, "No saved IDs, seeding baseline: home=$currentHomeId, lock=$currentLockId")
            prefs.edit()
                .putInt("flutter.dotdays_last_home_id", currentHomeId)
                .putInt("flutter.dotdays_last_lock_id", currentLockId)
                .commit()
            return "none"
        }

        val homeChanged = savedHomeId != -1 && currentHomeId != savedHomeId
        val lockChanged = savedLockId != -1 && currentLockId != savedLockId

        Log.d(TAG, "ID check: home($savedHomeId→$currentHomeId) lock($savedLockId→$currentLockId)")

        val result = when {
            homeChanged && lockChanged -> "both"
            homeChanged -> "home"
            lockChanged -> "lock"
            else -> "none"
        }

        // Update saved IDs to current (so we don't keep showing the dialog)
        if (result != "none") {
            prefs.edit()
                .putInt("flutter.dotdays_last_home_id", currentHomeId)
                .putInt("flutter.dotdays_last_lock_id", currentLockId)
                .commit()
            Log.d(TAG, "Updated baseline IDs after detecting change: $result")
        }

        return result
    }
}
