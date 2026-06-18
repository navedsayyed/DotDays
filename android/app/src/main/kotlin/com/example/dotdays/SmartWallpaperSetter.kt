package com.example.dotdays

import android.app.WallpaperManager
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.drawable.BitmapDrawable
import android.os.Build
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

/**
 * Native wallpaper helper that handles the OEM quirk where many Android
 * manufacturers (Xiaomi, Samsung, Realme, OPPO, etc.) IGNORE the
 * FLAG_LOCK / FLAG_SYSTEM parameter in WallpaperManager.setStream()
 * and apply the wallpaper to BOTH screens regardless.
 *
 * WORKAROUND:
 * When the user only wants to update ONE screen (e.g., lock screen only):
 * 1. Save the OTHER screen's current wallpaper (home screen bitmap)
 * 2. Apply the new wallpaper to BOTH screens (because OEMs force this)
 * 3. Immediately restore the saved wallpaper to the OTHER screen
 *
 * This ensures the user's gallery wallpaper on the other screen is preserved.
 */
object SmartWallpaperSetter {

    private const val TAG = "SmartWallpaperSetter"

    /**
     * Apply wallpaper to the specified screen, working around OEM quirks.
     *
     * @param context Application context
     * @param imageBytes The wallpaper image bytes
     * @param location 1=home, 2=lock, 3=both
     * @return true if successful
     */
    fun applyWallpaper(context: Context, imageBytes: ByteArray, location: Int): Boolean {
        val wm = WallpaperManager.getInstance(context)

        // Set flag so WallpaperChangedReceiver knows DotDays is doing this
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        prefs.edit().putBoolean("flutter.dotdays_is_setting_wallpaper", true).commit()

        val result = try {
            when (location) {
                3 -> setBothScreens(wm, imageBytes)
                2 -> setLockScreenOnly(context, wm, imageBytes)
                1 -> setHomeScreenOnly(context, wm, imageBytes)
                else -> {
                    Log.e(TAG, "Invalid location: $location")
                    false
                }
            }
        } finally {
            // Clear flag after a short delay (wallpaper broadcast may be async)
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                prefs.edit().putBoolean("flutter.dotdays_is_setting_wallpaper", false).commit()
                Log.d(TAG, "Cleared is_setting flag")
            }, 3000) // 3 second delay to let broadcast fire first
        }

        // After successful apply, save current wallpaper IDs as baseline
        // so we can detect external changes on next app open
        if (result && Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                val homeId = wm.getWallpaperId(WallpaperManager.FLAG_SYSTEM)
                val lockId = wm.getWallpaperId(WallpaperManager.FLAG_LOCK)
                prefs.edit()
                    .putInt("flutter.dotdays_last_home_id", homeId)
                    .putInt("flutter.dotdays_last_lock_id", lockId)
                    .commit()
                Log.d(TAG, "Saved wallpaper IDs: home=$homeId, lock=$lockId")
            } catch (e: Exception) {
                Log.w(TAG, "Could not save wallpaper IDs: ${e.message}")
            }
        }

        return result
    }

    /**
     * Set wallpaper on both screens.
     */
    private fun setBothScreens(wm: WallpaperManager, imageBytes: ByteArray): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                wm.setStream(
                    ByteArrayInputStream(imageBytes), null, false,
                    WallpaperManager.FLAG_SYSTEM or WallpaperManager.FLAG_LOCK
                )
            } else {
                wm.setStream(ByteArrayInputStream(imageBytes))
            }
            Log.d(TAG, "Set wallpaper on both screens")
            true
        } catch (e: IOException) {
            Log.e(TAG, "Failed to set both screens: ${e.message}")
            false
        }
    }

    /**
     * Set wallpaper ONLY on lock screen, preserving home screen.
     *
     * Strategy:
     * 1. Save current home screen wallpaper bitmap
     * 2. Try setting lock screen only (FLAG_LOCK)
     * 3. Check if home screen was also changed (OEM quirk)
     * 4. If yes, restore home screen from saved bitmap
     */
    private fun setLockScreenOnly(context: Context, wm: WallpaperManager, imageBytes: ByteArray): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            // Pre-API 24: can't set lock screen separately at all
            return setBothScreens(wm, imageBytes)
        }

        try {
            // Step 1: Save the current home screen wallpaper
            val homeScreenBitmap = getWallpaperBitmap(context, wm, WallpaperManager.FLAG_SYSTEM)
            val homeWallpaperId = wm.getWallpaperId(WallpaperManager.FLAG_SYSTEM)
            Log.d(TAG, "Saved home screen wallpaper (id=$homeWallpaperId, bitmap=${homeScreenBitmap != null})")

            // Step 2: Set lock screen wallpaper
            wm.setStream(
                ByteArrayInputStream(imageBytes), null, false,
                WallpaperManager.FLAG_LOCK
            )
            Log.d(TAG, "Set lock screen wallpaper")

            // Step 3: Check if OEM also changed the home screen
            val newHomeWallpaperId = wm.getWallpaperId(WallpaperManager.FLAG_SYSTEM)
            if (newHomeWallpaperId != homeWallpaperId && homeScreenBitmap != null) {
                // OEM quirk detected! Home screen was changed too. Restore it.
                Log.w(TAG, "OEM quirk: home screen was also changed (id $homeWallpaperId → $newHomeWallpaperId). Restoring...")
                wm.setBitmap(homeScreenBitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                homeScreenBitmap.recycle()
                Log.d(TAG, "Home screen wallpaper restored")
            } else {
                homeScreenBitmap?.recycle()
                Log.d(TAG, "Home screen was not affected (no OEM quirk)")
            }

            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set lock screen only: ${e.message}")
            return false
        }
    }

    /**
     * Set wallpaper ONLY on home screen, preserving lock screen.
     */
    private fun setHomeScreenOnly(context: Context, wm: WallpaperManager, imageBytes: ByteArray): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return setBothScreens(wm, imageBytes)
        }

        try {
            // Step 1: Save the current lock screen wallpaper
            val lockScreenBitmap = getWallpaperBitmap(context, wm, WallpaperManager.FLAG_LOCK)
            val lockWallpaperId = wm.getWallpaperId(WallpaperManager.FLAG_LOCK)
            Log.d(TAG, "Saved lock screen wallpaper (id=$lockWallpaperId, bitmap=${lockScreenBitmap != null})")

            // Step 2: Set home screen wallpaper
            wm.setStream(
                ByteArrayInputStream(imageBytes), null, false,
                WallpaperManager.FLAG_SYSTEM
            )
            Log.d(TAG, "Set home screen wallpaper")

            // Step 3: Check if OEM also changed the lock screen
            val newLockWallpaperId = wm.getWallpaperId(WallpaperManager.FLAG_LOCK)
            if (newLockWallpaperId != lockWallpaperId && lockScreenBitmap != null) {
                Log.w(TAG, "OEM quirk: lock screen was also changed. Restoring...")
                wm.setBitmap(lockScreenBitmap, null, true, WallpaperManager.FLAG_LOCK)
                lockScreenBitmap.recycle()
                Log.d(TAG, "Lock screen wallpaper restored")
            } else {
                lockScreenBitmap?.recycle()
                Log.d(TAG, "Lock screen was not affected")
            }

            return true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set home screen only: ${e.message}")
            return false
        }
    }

    /**
     * Get the current wallpaper as a Bitmap for the specified screen.
     *
     * @param which WallpaperManager.FLAG_SYSTEM or FLAG_LOCK
     * @return Bitmap or null if unavailable
     */
    private fun getWallpaperBitmap(context: Context, wm: WallpaperManager, which: Int): Bitmap? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                val pfd = wm.getWallpaperFile(which)
                if (pfd != null) {
                    val bitmap = BitmapFactory.decodeFileDescriptor(pfd.fileDescriptor)
                    pfd.close()
                    return bitmap
                }
            } catch (e: Exception) {
                Log.w(TAG, "getWallpaperFile($which) failed: ${e.message}")
            }
        }

        // Fallback: getDrawable() returns the system (home) wallpaper
        // This works for FLAG_SYSTEM but not FLAG_LOCK
        if (which == WallpaperManager.FLAG_SYSTEM) {
            try {
                val drawable = wm.drawable
                if (drawable is BitmapDrawable) {
                    return drawable.bitmap.copy(Bitmap.Config.ARGB_8888, false)
                }
            } catch (e: Exception) {
                Log.w(TAG, "getDrawable() fallback failed: ${e.message}")
            }
        }

        return null
    }
}
