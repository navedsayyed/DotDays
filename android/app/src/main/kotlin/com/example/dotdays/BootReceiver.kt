package com.example.dotdays

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log

/**
 * Re-registers background tasks after:
 * - Phone reboot (BOOT_COMPLETED)
 * - App update (MY_PACKAGE_REPLACED)
 * - Quick boot (QUICKBOOT_POWERON — Xiaomi/Realme/OPPO)
 *
 * Sets a "needs_reschedule" flag so the Flutter app re-schedules the
 * midnight Dart alarm on next launch. Also re-schedules the native
 * pre-check alarm that detects external wallpaper changes.
 */
class BootReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.d(TAG, "Boot/update received: ${intent.action}")

            // Set flag so Flutter re-schedules the midnight Dart alarm
            val prefs: SharedPreferences = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            prefs.edit()
                .putBoolean("flutter.needs_reschedule", true)
                .commit()

            // Re-schedule the native pre-check alarm (23:50 nightly)
            try {
                PreCheckReceiver.scheduleNext(context)
                Log.d(TAG, "Pre-check alarm re-scheduled after boot")
            } catch (e: Exception) {
                Log.e(TAG, "Error scheduling pre-check: ${e.message}")
            }
        }
    }
}
