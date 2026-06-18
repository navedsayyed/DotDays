package com.example.dotdays

import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.util.Log
import io.flutter.app.FlutterApplication

/**
 * Custom Application class that registers the WallpaperChangedReceiver
 * dynamically. This ensures the receiver lives as long as the process
 * (which Android keeps alive most of the time).
 *
 * ACTION_WALLPAPER_CHANGED is an implicit broadcast that can't be
 * registered in the manifest on Android 8+, so we register it here.
 */
class DotDaysApplication : FlutterApplication() {

    companion object {
        private const val TAG = "DotDaysApplication"
    }

    private val wallpaperChangedReceiver = WallpaperChangedReceiver()

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Application created")

        // Register wallpaper change listener (detects external wallpaper changes)
        try {
            val filter = IntentFilter(Intent.ACTION_WALLPAPER_CHANGED)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(wallpaperChangedReceiver, filter, RECEIVER_NOT_EXPORTED)
            } else {
                registerReceiver(wallpaperChangedReceiver, filter)
            }
            Log.d(TAG, "WallpaperChangedReceiver registered")
        } catch (e: Exception) {
            Log.e(TAG, "Error registering WallpaperChangedReceiver: ${e.message}")
        }
    }
}
