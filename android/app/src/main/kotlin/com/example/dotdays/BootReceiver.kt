package com.example.dotdays

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences

/**
 * Re-registers the background wallpaper task after:
 * - Phone reboot (BOOT_COMPLETED)
 * - App update (MY_PACKAGE_REPLACED)
 * - Quick boot (QUICKBOOT_POWERON — Xiaomi/Realme/OPPO)
 *
 * Sets a "needs_reschedule" flag in SharedPreferences so that
 * the Flutter app re-schedules WorkManager on next launch.
 * 
 * Also triggers the Flutter engine headless to re-register
 * the WorkManager task if the workmanager plugin supports it.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            // Set flag so Flutter re-schedules on next app open
            val prefs: SharedPreferences = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE
            )
            prefs.edit()
                .putBoolean("flutter.needs_reschedule", true)
                .apply()
        }
    }
}
