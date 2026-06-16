import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';

class WallpaperService {
  WallpaperService._();

  static const int locationLockScreen = WallpaperManagerFlutter.lockScreen;
  static const int locationHomeScreen = WallpaperManagerFlutter.homeScreen;
  static const int locationBothScreens = WallpaperManagerFlutter.bothScreens;

  /// Smart wallpaper channel — registered via SmartWallpaperPlugin which
  /// works on ALL Flutter engines (both foreground and background).
  /// This is the preferred channel for OEM-aware wallpaper setting.
  static const _smartChannel = MethodChannel('com.example.dotdays/smart_wallpaper');

  /// Legacy channel — only available in foreground (registered in MainActivity)
  static const _idChannel = MethodChannel('com.example.dotdays/wallpaper_id');

  /// Capture a widget tree identified by [boundaryKey] to a PNG file.
  static Future<File?> captureWidget(GlobalKey boundaryKey) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      return await _saveToFile(bytes);
    } catch (e) {
      debugPrint('WallpaperService captureWidget error: $e');
      return null;
    }
  }

  static Future<File> _saveToFile(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/life_in_dots_wallpaper.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  /// Apply the saved wallpaper image to the specified screen location.
  ///
  /// Uses our native SmartWallpaperSetter which works around the OEM quirk
  /// where many Android manufacturers (Xiaomi, Samsung, Realme, etc.)
  /// IGNORE the FLAG_LOCK/FLAG_SYSTEM parameter and apply wallpaper to
  /// BOTH screens regardless.
  ///
  /// The native code:
  /// 1. Saves the other screen's wallpaper before applying
  /// 2. Applies the new wallpaper (may hit both screens on OEM phones)
  /// 3. Detects if the other screen was changed (OEM quirk)
  /// 4. Restores the other screen's wallpaper if needed
  static Future<bool> applyWallpaper(File imageFile, int location) async {
    try {
      if (Platform.isAndroid) {
        final imageBytes = await imageFile.readAsBytes();

        // Try the SmartWallpaperPlugin channel (works on ALL engines,
        // including background). This is the primary path.
        try {
          final result = await _smartChannel.invokeMethod('smartSetWallpaper', {
            'imageBytes': imageBytes,
            'location': location,
          });
          if (result == true) {
            debugPrint('WallpaperService: applied via SmartWallpaperPlugin (location=$location)');
            return true;
          }
        } on MissingPluginException {
          debugPrint('WallpaperService: SmartWallpaperPlugin not available');
        } catch (e) {
          debugPrint('WallpaperService: SmartWallpaperPlugin failed ($e)');
        }

        // Fallback: try the MainActivity channel (foreground only)
        try {
          final result = await _idChannel.invokeMethod('smartSetWallpaper', {
            'imageBytes': imageBytes,
            'location': location,
          });
          if (result == true) {
            debugPrint('WallpaperService: applied via MainActivity channel (location=$location)');
            return true;
          }
        } on MissingPluginException {
          debugPrint('WallpaperService: MainActivity channel not available');
        } catch (e) {
          debugPrint('WallpaperService: MainActivity channel failed ($e)');
        }
      }

      // Last resort: use wallpaper_manager_flutter package
      // (won't handle OEM quirks, but better than nothing)
      debugPrint('WallpaperService: using wallpaper_manager_flutter fallback');
      final result = await WallpaperManagerFlutter().setWallpaper(
        imageFile,
        location,
      );
      return result == true;
    } catch (e) {
      debugPrint('WallpaperService applyWallpaper error: $e');
      return false;
    }
  }

  /// Get the saved wallpaper file path (if any).
  static Future<File?> getSavedWallpaper() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/life_in_dots_wallpaper.png');
      if (await file.exists()) return file;
    } catch (_) {}
    return null;
  }
}
