package com.example.dotdays

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.work.*
import java.util.concurrent.TimeUnit

/**
 * Re-schedules the daily wallpaper WorkManager task after:
 * - Phone reboot (BOOT_COMPLETED)
 * - App update (MY_PACKAGE_REPLACED)
 * - Quick boot (QUICKBOOT_POWERON — Xiaomi/Realme/OPPO)
 *
 * This ensures the background wallpaper update survives phone restarts.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            intent.action == "android.intent.action.QUICKBOOT_POWERON"
        ) {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.NOT_REQUIRED)
                .setRequiresBatteryNotLow(false)
                .build()

            val workRequest = PeriodicWorkRequestBuilder<DummyWorker>(
                15, TimeUnit.MINUTES
            )
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                "life_in_dots_unique",
                ExistingPeriodicWorkPolicy.KEEP,
                workRequest
            )
        }
    }
}

/**
 * Minimal worker stub — the real work is done by Flutter's WorkManager
 * callback dispatcher. This just ensures WorkManager is registered
 * natively after boot, and Flutter's Workmanager plugin picks it up.
 */
class DummyWorker(context: Context, params: WorkerParameters) :
    Worker(context, params) {
    override fun doWork(): Result {
        // Flutter's Workmanager plugin handles the actual execution
        // via callbackDispatcher. This is a fallback registration.
        return Result.success()
    }
}
