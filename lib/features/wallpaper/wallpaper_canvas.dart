import 'package:flutter/material.dart';
import '../../shared/models/app_settings.dart';
import '../../shared/models/calendar_type.dart';
import '../../core/theme/app_colors.dart';
import '../../services/date_service.dart';
import '../../core/constants/app_constants.dart';

/// The actual wallpaper content widget.
/// Rendered via RepaintBoundary → PNG.
/// Content is placed only in the middle safe zone
/// (top 28%, bottom 18% excluded for lock screen widgets).
class WallpaperCanvas extends StatelessWidget {
  final AppSettings settings;

  const WallpaperCanvas({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final h = constraints.maxHeight;
        final topPad = h * AppConstants.wallpaperTopSafePercent;
        // Year, Life, & Goal wallpapers use minimal bottom padding to push text near bottom
        final botPad = (settings.calendarType == CalendarType.year ||
                settings.calendarType == CalendarType.life ||
                settings.calendarType == CalendarType.goal)
            ? h * 0.04
            : h * AppConstants.wallpaperBottomSafePercent;

        return Container(
          color: AppColors.background,
          child: Padding(
            padding: EdgeInsets.only(
                top: topPad, bottom: botPad, left: 20, right: 20),
            child: _buildContent(context),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (settings.calendarType) {
      case CalendarType.life:
        return _LifeWallpaper(settings: settings);
      case CalendarType.year:
        return const _YearWallpaper();
      case CalendarType.goal:
        return _GoalWallpaper(settings: settings);
    }
  }
}

class _LifeWallpaper extends StatelessWidget {
  final AppSettings settings;
  const _LifeWallpaper({required this.settings});

  @override
  Widget build(BuildContext context) {
    final dob = settings.dateOfBirth;
    if (dob == null) return const SizedBox.shrink();

    final daysLived = DateService.daysLived(dob);
    final weeksLived = (daysLived / 7).floor();
    final totalWeeks = settings.lifespan * 52; // 80 years × 52 weeks = 4160
    final percent = ((weeksLived / totalWeeks) * 100).toStringAsFixed(1);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Dot grid: 52 cols (weeks) × lifespan rows (years)
        Expanded(
          child: _WallpaperDotGrid(
            total: totalWeeks,
            lived: weeksLived.clamp(0, totalWeeks),
            livedColor: settings.livedDotColor,
            fixedCols: 52,
          ),
        ),
        const SizedBox(height: 4),
        // Bottom info: "XX.X% to YY" — tiny, centered
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$percent%',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 5,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              ' to ${settings.lifespan}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _YearWallpaper extends StatelessWidget {
  const _YearWallpaper();

  @override
  Widget build(BuildContext context) {
    final passed = DateService.dayOfYear;
    final total = DateService.isLeapYear ? 366 : 365;
    final remaining = total - passed;
    final percent = ((passed / total) * 100).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Dot grid fills most of the space
        const Expanded(
          child: _WallpaperDotGrid(
            total: 365,
            lived: 0,
            livedColor: AppColors.dotLived,
            useYear: true,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${remaining}d left',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              ' · ',
              style: TextStyle(
                color: AppColors.textDisabled,
                fontSize: 5,
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              color: AppColors.textSecondary,
              size: 6,
            ),
            const SizedBox(width: 1),
            Text(
              'Personal',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GoalWallpaper extends StatelessWidget {
  final AppSettings settings;
  const _GoalWallpaper({required this.settings});

  @override
  Widget build(BuildContext context) {
    final start = settings.goalStart;
    final end = settings.goalEnd;
    if (start == null || end == null) return const SizedBox.shrink();

    final completed = DateService.goalPassed(start);
    final remaining = DateService.goalRemaining(start, end);
    final total = DateService.goalTotal(start, end);
    final percent = ((completed / total) * 100).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Goal name — small centered label like the reference
        Text(
          settings.goalName ?? 'My Goal',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 7,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        // Full dot grid: 1 dot = 1 day, same style as Year
        Expanded(
          child: _WallpaperDotGrid(
            total: total,
            lived: completed.clamp(0, total),
            livedColor: AppColors.dotLived,
            fixedCols: 15,
          ),
        ),
        const SizedBox(height: 4),
        // Bottom info: "Xd left · X%" — matching Year style
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${remaining}d left',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Text(
              ' · ',
              style: TextStyle(
                color: AppColors.textDisabled,
                fontSize: 5,
              ),
            ),
            Text(
              '$percent%',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WallpaperDotGrid extends StatelessWidget {
  final int total;
  final int lived;
  final Color livedColor;
  final bool useYear;
  final int? fixedCols;

  const _WallpaperDotGrid({
    required this.total,
    required this.lived,
    required this.livedColor,
    this.useYear = false,
    this.fixedCols,
  });

  @override
  Widget build(BuildContext context) {
    final actualLived = useYear ? DateService.dayOfYear - 1 : lived;
    return LayoutBuilder(builder: (ctx, box) {
      // Fixed columns mode (year=15, life=52, etc.)
      if (fixedCols != null || useYear) {
        final cols = fixedCols ?? 15;
        final rows = (total / cols).ceil();

        // Step size from width
        final stepFromWidth = box.maxWidth / cols;
        // Fit within height if needed
        final stepFromHeight = box.maxHeight.isFinite
            ? box.maxHeight / rows
            : double.infinity;
        final step =
            stepFromWidth < stepFromHeight ? stepFromWidth : stepFromHeight;

        final spacing = step * 0.2;
        final dotSize = step - spacing;
        final height = rows * step;

        return SizedBox(
          width: box.maxWidth,
          height:
              height.clamp(0, box.maxHeight.isFinite ? box.maxHeight : height),
          child: CustomPaint(
            painter: _WpDotPainter(
              total: total,
              lived: actualLived,
              livedColor: livedColor,
              dotSize: dotSize,
              spacing: spacing,
              fixedCols: cols,
            ),
          ),
        );
      }

      // Default mode: auto columns with small dots
      const dotSize = 4.0;
      const spacing = 2.5;
      const step = dotSize + spacing;
      final cols = (box.maxWidth / step).floor();
      if (cols == 0) return const SizedBox.shrink();
      final rows = (total / cols).ceil();
      final height = rows * step;

      return SizedBox(
        width: box.maxWidth,
        height:
            height.clamp(0, box.maxHeight.isFinite ? box.maxHeight : height),
        child: CustomPaint(
          painter: _WpDotPainter(
            total: total,
            lived: actualLived,
            livedColor: livedColor,
            dotSize: dotSize,
            spacing: spacing,
          ),
        ),
      );
    });
  }
}

class _WpDotPainter extends CustomPainter {
  final int total;
  final int lived;
  final Color livedColor;
  final double dotSize;
  final double spacing;
  final int? fixedCols;

  _WpDotPainter({
    required this.total,
    required this.lived,
    required this.livedColor,
    this.dotSize = 4.0,
    this.spacing = 2.5,
    this.fixedCols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final step = dotSize + spacing;
    final cols = fixedCols ?? (size.width / step).floor();
    if (cols == 0) return;
    final r = dotSize / 2;
    final livedP = Paint()..color = livedColor;
    final todayP = Paint()..color = AppColors.dotToday;
    final futureP = Paint()..color = AppColors.dotFuture;

    for (int i = 0; i < total; i++) {
      final cx = (i % cols) * step + r;
      final cy = (i ~/ cols) * step + r;
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

  @override
  bool shouldRepaint(_WpDotPainter o) => o.total != total || o.lived != lived;
}
