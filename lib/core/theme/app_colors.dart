import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF000000);
  static const Color surface = Color(0xFF111317);
  static const Color surfaceVariant = Color(0xFF12141A);
  static const Color border = Color(0xFF232831);
  static const Color borderSubtle = Color(0xFF1F242D);

  static const Color accent = Color(0xFFFF6600);
  static const Color accentDark = Color(0xFFCC5200);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9AA3AD);
  static const Color textMuted = Color(0xFF7A8491);
  static const Color textDim = Color(0xFF697382);
  static const Color textDisabled = Color(0xFF555555);
  static const Color textHint = Color(0xFF444444);

  static const Color dotLived = Color(0xFFFFFFFF);
  static const Color dotToday = Color(0xFFFF6600);
  static const Color dotFuture = Color(0xFF1E1E1E);

  // Color options for lived dots
  static const List<Color> livedDotColors = [
    Color(0xFFFFFFFF),
    Color(0xFF3A6FF4),
    Color(0xFF22C47A),
  ];
}
