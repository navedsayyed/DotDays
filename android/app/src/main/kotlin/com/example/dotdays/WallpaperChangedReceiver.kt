package com.example.dotdays

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

/**
 * Listens for ACTION_WALLPAPER_CHANGED broadcast.
 *
 * When the user changes their wallpaper from Gallery or another app,
 * this receiver fires and shows a notification telling them how to
 * prevent DotDays from overwriting it at midnight.
 *
 * We skip the notification when DotDays itself changed the wallpaper
 * (detected via the "dotdays_is_setting_wallpaper" flag).
 *
 * NOTE: This receiver is registered DYNAMICALLY in DotDaysApplication
 * (not in manifest) because ACTION_WALLPAPER_CHANGED is an implicit
 * broadcast restricted on Android 8+.
 */
class WallpaperChangedReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "WallpaperChangedRcvr"
        private const val CHANNEL_ID = "dotdays_wallpaper_tip"
        private const val NOTIFICATION_ID = 2001
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val KEY_IS_SETTING = "flutter.dotdays_is_setting_wallpaper"
        private const val KEY_AUTO_HOME = "flutter.auto_update_home"
        private const val KEY_AUTO_LOCK = "flutter.auto_update_lock"
        private const val KEY_ONBOARDING = "flutter.onboarding_complete"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_WALLPAPER_CHANGED) return

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

        // Skip if onboarding not done (user hasn't set DotDays wallpaper yet)
        val onboardingDone = prefs.getBoolean(KEY_ONBOARDING, false)
        if (!onboardingDone) {
            Log.d(TAG, "Onboarding not done, skipping")
            return
        }

        // Skip if DotDays itself is setting the wallpaper
        val isDotDaysSetting = prefs.getBoolean(KEY_IS_SETTING, false)
        if (isDotDaysSetting) {
            Log.d(TAG, "DotDays is setting wallpaper, skipping notification")
            return
        }

        // Skip if both auto-updates are already off (user already protected)
        val autoHome = prefs.getBoolean(KEY_AUTO_HOME, true)
        val autoLock = prefs.getBoolean(KEY_AUTO_LOCK, true)
        if (!autoHome && !autoLock) {
            Log.d(TAG, "Both auto-updates already off, skipping")
            return
        }

        Log.d(TAG, "External wallpaper change detected! Showing notification")
        showNotification(context)
    }

    private fun showNotification(context: Context) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as NotificationManager

        // Create notification channel (required for Android 8+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Wallpaper Tips",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Tips about wallpaper auto-update settings"
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Tapping notification opens DotDays (Settings tab = tab 2)
        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("tab", 2) // Settings tab
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_gallery)
            .setContentTitle("Wallpaper changed!")
            .setContentText("Turn off auto-update in Settings to keep your new wallpaper.")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("You changed your wallpaper. DotDays will overwrite it at midnight unless you turn off auto-update for that screen in Settings."))
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }
}
