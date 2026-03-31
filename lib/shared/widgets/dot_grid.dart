import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// High-performance dot grid rendered via CustomPainter.
/// Avoids building thousands of widget instances.
class DotGridPainter extends CustomPainter {
  final int totalDots;
  final int passedDots;
  final int todayIndex;
  final Color livedColor;
  final Color todayColor;
  final Color futureColor;
  final double dotSize;
  final double spacing;

  DotGridPainter({
    required this.totalDots,
    required this.passedDots,
    required this.todayIndex,
    this.livedColor = AppColors.dotLived,
    this.todayColor = AppColors.dotToday,
    this.futureColor = AppColors.dotFuture,
    this.dotSize = 5.0,
    this.spacing = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final step = dotSize + spacing;
    final cols = (size.width / step).floor();
    if (cols == 0) return;

    final livedPaint = Paint()..color = livedColor;
    final todayPaint = Paint()..color = todayColor;
    final futurePaint = Paint()..color = futureColor;
    final radius = dotSize / 2;

    for (int i = 0; i < totalDots; i++) {
      final col = i % cols;
      final row = i ~/ cols;
      final cx = col * step + radius;
      final cy = row * step + radius;
      final offset = Offset(cx, cy);

      Paint paint;
      if (i == todayIndex) {
        paint = todayPaint;
      } else if (i < passedDots) {
        paint = livedPaint;
      } else {
        paint = futurePaint;
      }

      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(DotGridPainter oldDelegate) {
    return oldDelegate.totalDots != totalDots ||
        oldDelegate.passedDots != passedDots ||
        oldDelegate.todayIndex != todayIndex ||
        oldDelegate.livedColor != livedColor ||
        oldDelegate.todayColor != todayColor;
  }

  /// Calculate the required height for the grid given a width.
  static double requiredHeight(
      int totalDots, double width, double dotSize, double spacing) {
    final step = dotSize + spacing;
    final cols = (width / step).floor();
    if (cols == 0) return 0;
    final rows = (totalDots / cols).ceil();
    return rows * step;
  }
}

/// Stateless wrapper around DotGridPainter.
class DotGrid extends StatelessWidget {
  final int totalDots;
  final int passedDots;
  final int todayIndex;
  final Color livedColor;
  final double dotSize;
  final double spacing;

  const DotGrid({
    super.key,
    required this.totalDots,
    required this.passedDots,
    required this.todayIndex,
    this.livedColor = AppColors.dotLived,
    this.dotSize = 5.0,
    this.spacing = 3.0,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = DotGridPainter.requiredHeight(
            totalDots, width, dotSize, spacing);

        return SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: DotGridPainter(
              totalDots: totalDots,
              passedDots: passedDots,
              todayIndex: passedDots > 0 ? passedDots - 1 : 0,
              livedColor: livedColor,
              dotSize: dotSize,
              spacing: spacing,
            ),
          ),
        );
      },
    );
  }
}
