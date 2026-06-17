package com.example.dotdays

import android.content.Context
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Flutter plugin that registers the SmartWallpaperSetter method channel
 * on ANY FlutterEngine — including the background engine created by
 * android_alarm_manager_plus.
 *
 * This implements FlutterPlugin so it auto-registers via
 * GeneratedPluginRegistrant on all engines.
 *
 * The method channel provides:
 * - smartSetWallpaper: Applies wallpaper with OEM quirk workaround
 */
class SmartWallpaperPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "SmartWallpaperPlugin"
        private const val CHANNEL = "com.example.dotdays/smart_wallpaper"
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
            else -> result.notImplemented()
        }
    }
}
