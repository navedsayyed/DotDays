package com.example.dotdays

import android.app.WallpaperManager
import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.util.Log

/**
 * Native Kotlin helper that checks wallpaper IDs directly from WallpaperManager
 * and SharedPreferences. This works in ANY context (foreground, background service,
 * alarm callback, BroadcastReceiver) without needing Flutter method channels.
 *
 * Flow:
 * 1. DotDays applies wallpaper → saveCurrentIds() stores system wallpaper IDs
 * 2. User changes a screen from Gallery → system wallpaper ID changes
 * 3. Before midnight update → computeAndSaveSmartLocation() detects the mismatch
 *    and returns which screens DotDays should actually update
 */
object WallpaperIdChecker {

    private const val TAG = "WallpaperIdChecker"
    private const val PREFS_NAME = "FlutterSharedPreferences"

    // Keys must match what Dart's SharedPreferences uses (flutter. prefix)
    private const val KEY_HOME_ID = "flutter.dotdays_home_wallpaper_id"
    private const val KEY_LOCK_ID = "flutter.dotdays_lock_wallpaper_id"
    private const val KEY_WALLPAPER_LOCATION = "flutter.wallpaper_location"
    private const val KEY_SMART_LOCATION = "flutter.dotdays_smart_wallpaper_location"
    private const val KEY_IDS_STALE = "flutter.dotdays_ids_stale"

    // Wallpaper location constants (match WallpaperManagerFlutter)
    private const val LOCATION_HOME = 1
    private const val LOCATION_LOCK = 2
    private const val LOCATION_BOTH = 3
    private const val LOCATION_SKIP = -1

    /**
     * Read current wallpaper IDs from the system.
     * Returns Pair(homeId, lockId). Returns (-1, -1) on pre-API 24.
     */
    private fun getCurrentIds(context: Context): Pair<Int, Int> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val wm = WallpaperManager.getInstance(context)
            val homeId = wm.getWallpaperId(WallpaperManager.FLAG_SYSTEM)
            val lockId = wm.getWallpaperId(WallpaperManager.FLAG_LOCK)
            return Pair(homeId, lockId)
        }
        return Pair(-1, -1)
    }

    private fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    /**
     * Save the current wallpaper IDs to SharedPreferences.
     * Call this after DotDays successfully applies a wallpaper.
     * Uses commit() for synchronous, guaranteed write.
     */
    fun saveCurrentIds(context: Context) {
        val (homeId, lockId) = getCurrentIds(context)
        val prefs = getPrefs(context)
        prefs.edit()
            .putString(KEY_HOME_ID, homeId.toString())
            .putString(KEY_LOCK_ID, lockId.toString())
            .remove(KEY_IDS_STALE)
            .commit() // Synchronous write — guarantees data is on disk
        Log.d(TAG, "Saved IDs: home=$homeId, lock=$lockId")
    }

    /**
     * Compute which screen(s) DotDays should update, based on comparing
     * current system wallpaper IDs against saved IDs.
     *
     * This runs entirely in native code — no Flutter engine or method channels needed.
     *
     * Writes the result to SharedPreferences under KEY_SMART_LOCATION so the
     * Dart background callback can read it.
     *
     * Uses commit() for synchronous, guaranteed writes.
     *
     * @return The smart location (1=home, 2=lock, 3=both, -1=skip)
     */
    fun computeAndSaveSmartLocation(context: Context): Int {
        val prefs = getPrefs(context)

        // If IDs are stale (background updated wallpaper, changing system IDs),
        // refresh baseline first so we don't falsely detect an "external change"
        val idsStale = prefs.getBoolean(KEY_IDS_STALE, false)
        if (idsStale) {
            Log.d(TAG, "IDs stale from background update, refreshing baseline")
            saveCurrentIds(context) // Re-saves current system IDs as new baseline
            // After refresh, saved IDs = current IDs, so smart = original
            val originalLocation = prefs.getInt(KEY_WALLPAPER_LOCATION, LOCATION_BOTH)
            prefs.edit()
                .putInt(KEY_SMART_LOCATION, originalLocation)
                .commit()
            Log.d(TAG, "Stale refresh done, smart=$originalLocation")
            return originalLocation
        }

        val originalLocation = prefs.getInt(KEY_WALLPAPER_LOCATION, LOCATION_BOTH)
        val (currentHome, currentLock) = getCurrentIds(context)

        // If we can't read IDs (pre-API 24), fall back to original
        if (currentHome == -1 && currentLock == -1) {
            Log.d(TAG, "IDs unavailable (pre-API 24?), using original=$originalLocation")
            prefs.edit().putInt(KEY_SMART_LOCATION, originalLocation).commit()
            return originalLocation
        }

        val savedHomeStr = prefs.getString(KEY_HOME_ID, null)
        val savedLockStr = prefs.getString(KEY_LOCK_ID, null)

        // If no saved IDs (first run or cleared), use original
        if (savedHomeStr == null && savedLockStr == null) {
            Log.d(TAG, "No saved IDs, using original=$originalLocation")
            prefs.edit().putInt(KEY_SMART_LOCATION, originalLocation).commit()
            return originalLocation
        }

        val savedHome = savedHomeStr?.toIntOrNull() ?: -1
        val savedLock = savedLockStr?.toIntOrNull() ?: -1

        val homeMatches = savedHome != -1 && currentHome == savedHome
        val lockMatches = savedLock != -1 && currentLock == savedLock

        // When wallpaper is set to "both", Android may return -1 for lock ID
        // (no separate lock screen wallpaper — it mirrors home).
        val lockWasMirrored = savedLock == -1 && currentLock == -1
        val effectiveLockMatches = lockMatches || (lockWasMirrored && homeMatches)

        Log.d(TAG, "home: current=$currentHome saved=$savedHome match=$homeMatches")
        Log.d(TAG, "lock: current=$currentLock saved=$savedLock match=$effectiveLockMatches")

        val smartLocation = when (originalLocation) {
            LOCATION_BOTH -> when {
                homeMatches && effectiveLockMatches -> LOCATION_BOTH
                homeMatches -> LOCATION_HOME
                effectiveLockMatches -> LOCATION_LOCK
                else -> LOCATION_SKIP
            }
            LOCATION_HOME -> if (homeMatches) LOCATION_HOME else LOCATION_SKIP
            LOCATION_LOCK -> if (effectiveLockMatches) LOCATION_LOCK else LOCATION_SKIP
            else -> originalLocation
        }

        prefs.edit().putInt(KEY_SMART_LOCATION, smartLocation).commit()
        Log.d(TAG, "Smart location: $smartLocation (original=$originalLocation)")
        return smartLocation
    }
}
