import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/app_constants.dart';
import '../shared/models/calendar_type.dart';

/// Headless renderer that generates the wallpaper PNG without needing
/// a widget tree. This can run in a background isolate (WorkManager).
class HeadlessWallpaperRenderer {
  HeadlessWallpaperRenderer._();

  // Standard phone resolution for wallpaper
  static const double _width = 1080;
  static const double _height = 2340;

  // Colors matching AppColors
  static const Color _background = Color(0xFF08090B);
  static const Color _dotLived = Color(0xFFFFFFFF);
  static const Color _dotToday = Color(0xFFFF6B35);
  static const Color _dotFuture = Color(0xFF2A2D35);
  static const Color _accent = Color(0xFFFF6B35);
  static const Color _textSecondary = Color(0xFF8E9196);
  static const Color _textDisabled = Color(0xFF4A4D55);

  /// Generate wallpaper image based on stored settings and return the file.
  static Future<File?> render({
    required CalendarType calendarType,
    DateTime? dateOfBirth,
    int lifespan = 80,
    String? goalName,
    DateTime? goalStart,
    DateTime? goalEnd,
    Color livedDotColor = _dotLived,
  }) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, _width, _height));

      // Fill background
      canvas.drawRect(
        Rect.fromLTWH(0, 0, _width, _height),
        Paint()..color = _background,
      );

      // Safe area padding
      final topPad = _height * AppConstants.wallpaperTopSafePercent;
      final botPad = _height * 0.04;
      final leftPad = 60.0;
      final rightPad = 60.0;

      final contentWidth = _width - leftPad - rightPad;
      final contentHeight = _height - topPad - botPad;

      switch (calendarType) {
        case CalendarType.year:
          _renderYear(canvas, leftPad, topPad, contentWidth, contentHeight);
          break;
        case CalendarType.life:
          _renderLife(canvas, leftPad, topPad, contentWidth, contentHeight,
              dateOfBirth, lifespan, livedDotColor);
          break;
        case CalendarType.goal:
          _renderGoal(canvas, leftPad, topPad, contentWidth, contentHeight,
              goalName, goalStart, goalEnd);
          break;
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(_width.toInt(), _height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      return await _saveToFile(bytes);
    } catch (e) {
      debugPrint('HeadlessWallpaperRenderer error: $e');
      return null;
    }
  }

  static void _renderYear(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
  ) {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final dayOfYear = now.difference(startOfYear).inDays + 1;
    final isLeap = (now.year % 4 == 0 && now.year % 100 != 0) ||
        (now.year % 400 == 0);
    final total = isLeap ? 366 : 365;
    final remaining = total - dayOfYear;
    final percent = ((dayOfYear / total) * 100).round();

    // Reserve space for bottom text
    const bottomTextHeight = 40.0;
    final gridHeight = height - bottomTextHeight;

    _drawDotGrid(
      canvas,
      left: left,
      top: top,
      width: width,
      height: gridHeight,
      total: total,
      lived: dayOfYear - 1, // 0-indexed for "today" highlight
      livedColor: _dotLived,
      fixedCols: 15,
    );

    // Bottom text: "Xd left · X%"
    _drawBottomText(
      canvas,
      centerX: left + width / 2,
      y: top + height - 10,
      parts: [
        _TextPart('${remaining}d left', _accent),
        _TextPart(' · ', _textDisabled),
        _TextPart('$percent%', _textSecondary),
      ],
    );
  }

  static void _renderLife(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
    DateTime? dob,
    int lifespan,
    Color livedColor,
  ) {
    if (dob == null) return;

    final daysLived = DateTime.now().difference(dob).inDays;
    final weeksLived = (daysLived / 7).floor();
    final totalWeeks = lifespan * 52;
    final percent = ((weeksLived / totalWeeks) * 100).toStringAsFixed(1);

    const bottomTextHeight = 40.0;
    final gridHeight = height - bottomTextHeight;

    _drawDotGrid(
      canvas,
      left: left,
      top: top,
      width: width,
      height: gridHeight,
      total: totalWeeks,
      lived: weeksLived.clamp(0, totalWeeks),
      livedColor: livedColor,
      fixedCols: 52,
    );

    _drawBottomText(
      canvas,
      centerX: left + width / 2,
      y: top + height - 10,
      parts: [
        _TextPart('$percent%', _accent),
        _TextPart(' to $lifespan', _textSecondary),
      ],
    );
  }

  static void _renderGoal(
    Canvas canvas,
    double left,
    double top,
    double width,
    double height,
    String? goalName,
    DateTime? goalStart,
    DateTime? goalEnd,
  ) {
    if (goalStart == null || goalEnd == null) return;

    final total = goalEnd.difference(goalStart).inDays.clamp(1, 99999);
    final completed =
        DateTime.now().difference(goalStart).inDays.clamp(0, 99999);
    final remaining = (total - completed).clamp(0, total);
    final percent = ((completed / total) * 100).round();

    // Draw goal name at top
    final nameText = goalName ?? 'My Goal';
    final nameParagraph = _makeParagraph(
      nameText,
      _textSecondary,
      21.0,
      width,
      textAlign: TextAlign.center,
      fontWeight: FontWeight.w500,
    );
    canvas.drawParagraph(
      nameParagraph,
      Offset(left, top),
    );

    const nameHeight = 40.0;
    const bottomTextHeight = 40.0;
    final gridHeight = height - nameHeight - bottomTextHeight;

    _drawDotGrid(
      canvas,
      left: left,
      top: top + nameHeight,
      width: width,
      height: gridHeight,
      total: total,
      lived: completed.clamp(0, total),
      livedColor: _dotLived,
      fixedCols: 15,
    );

    _drawBottomText(
      canvas,
      centerX: left + width / 2,
      y: top + height - 10,
      parts: [
        _TextPart('${remaining}d left', _accent),
        _TextPart(' · ', _textDisabled),
        _TextPart('$percent%', _textSecondary),
      ],
    );
  }

  static void _drawDotGrid(
    Canvas canvas, {
    required double left,
    required double top,
    required double width,
    required double height,
    required int total,
    required int lived,
    required Color livedColor,
    int? fixedCols,
  }) {
    final cols = fixedCols ?? 15;
    final rows = (total / cols).ceil();

    final stepFromWidth = width / cols;
    final stepFromHeight = height / rows;
    final step = stepFromWidth < stepFromHeight ? stepFromWidth : stepFromHeight;

    final spacing = step * 0.2;
    final dotSize = step - spacing;
    final r = dotSize / 2;

    final livedP = Paint()..color = livedColor;
    final todayP = Paint()..color = _dotToday;
    final futureP = Paint()..color = _dotFuture;

    for (int i = 0; i < total; i++) {
      final cx = left + (i % cols) * step + r;
      final cy = top + (i ~/ cols) * step + r;
      final offset = Offset(cx, cy);

      Paint p;
      if (i == lived) {
        p = todayP;
      } else if (i < lived) {
        p = livedP;
      } else {
        p = futureP;
      }
      canvas.drawCircle(offset, r, p);
    }
  }

  static void _drawBottomText(
    Canvas canvas, {
    required double centerX,
    required double y,
    required List<_TextPart> parts,
  }) {
    // Build a combined string and draw it centered
    final buffer = StringBuffer();
    for (final part in parts) {
      buffer.write(part.text);
    }

    final fullText = buffer.toString();
    final paragraph = _makeParagraph(
      fullText,
      _textSecondary,
      15.0,
      600,
      textAlign: TextAlign.center,
      parts: parts,
    );

    final textWidth = paragraph.maxIntrinsicWidth;
    canvas.drawParagraph(
      paragraph,
      Offset(centerX - textWidth / 2, y),
    );
  }

  static ui.Paragraph _makeParagraph(
    String text,
    Color color,
    double fontSize,
    double maxWidth, {
    TextAlign textAlign = TextAlign.left,
    FontWeight fontWeight = FontWeight.w500,
    List<_TextPart>? parts,
  }) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: textAlign,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );

    if (parts != null) {
      for (final part in parts) {
        builder.pushStyle(ui.TextStyle(
          color: part.color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ));
        builder.addText(part.text);
        builder.pop();
      }
    } else {
      builder.pushStyle(ui.TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ));
      builder.addText(text);
    }

    final paragraph = builder.build();
    paragraph.layout(ui.ParagraphConstraints(width: maxWidth));
    return paragraph;
  }

  static Future<File> _saveToFile(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/life_in_dots_wallpaper.png');
    await file.writeAsBytes(bytes);
    return file;
  }
}

class _TextPart {
  final String text;
  final Color color;
  _TextPart(this.text, this.color);
}
