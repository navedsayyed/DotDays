package com.example.dotdays

import android.util.Log
import io.flutter.app.FlutterApplication
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup

/**
 * Custom Application class that:
 * 1. Runs the wallpaper ID check on process creation (handles fresh process start)
 * 2. Schedules the PreCheckReceiver alarm for 23:50 tonight (handles long-lived process)
 * 3. Registers SmartWallpaperPlugin on all Flutter engines
 *
 * Together, these ensure the smart location is ALWAYS fresh before the
 * midnight Dart alarm fires — regardless of whether the process was
 * just created or has been alive for hours.
 */
class DotDaysApplication : FlutterApplication() {

    companion object {
        private const val TAG = "DotDaysApplication"
    }

    override fun onCreate() {
        super.onCreate()

        Log.d(TAG, "Application created")

        try {
            // 1. Run wallpaper ID check immediately (for fresh process starts)
            WallpaperIdChecker.computeAndSaveSmartLocation(this)
            Log.d(TAG, "Wallpaper ID check completed")
        } catch (e: Exception) {
            Log.e(TAG, "Error in wallpaper ID check: ${e.message}")
        }

        try {
            // 2. Schedule the nightly pre-check alarm (for long-lived processes).
            //    This fires at 23:50 every night, 10 minutes before the Dart alarm,
            //    ensuring a FRESH wallpaper ID comparison even if this process has
            //    been alive all day.
            PreCheckReceiver.scheduleNext(this)
            Log.d(TAG, "Pre-check alarm scheduled")
        } catch (e: Exception) {
            Log.e(TAG, "Error scheduling pre-check: ${e.message}")
        }
    }
}
