import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wallpaper_manager_flutter/wallpaper_manager_flutter.dart';

class WallpaperService {
  WallpaperService._();

  static const int locationLockScreen = WallpaperManagerFlutter.lockScreen;
  static const int locationHomeScreen = WallpaperManagerFlutter.homeScreen;
  static const int locationBothScreens = WallpaperManagerFlutter.bothScreens;

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
  static Future<bool> applyWallpaper(File imageFile, int location) async {
    try {
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
