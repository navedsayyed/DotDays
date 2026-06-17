package com.example.dotdays

import android.util.Log
import io.flutter.app.FlutterApplication

/**
 * Custom Application class.
 * Kept minimal — no detection logic. Per-screen auto-update is handled
 * entirely by SharedPreferences flags that the user controls via Settings.
 */
class DotDaysApplication : FlutterApplication() {

    companion object {
        private const val TAG = "DotDaysApplication"
    }

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Application created")
    }
}
