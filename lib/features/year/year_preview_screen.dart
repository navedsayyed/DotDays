import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/models/calendar_type.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/misc_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../services/date_service.dart';
import '../../routes/app_router.dart';

class YearPreviewScreen extends ConsumerWidget {
  const YearPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daysPassed = DateService.dayOfYear;
    final daysRemaining = DateService.daysRemainingInYear;
    final year = DateService.currentYear;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textMuted, size: 18),
              ),
              const SizedBox(height: 20),
              const KickerLabel('YEAR CALENDAR'),
              const SizedBox(height: 6),
              Text(
                '$year',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              StatTile(
                label: 'Days passed',
                value: '$daysPassed',
              ),
              StatTile(
                label: 'Days remaining in year',
                value: '$daysRemaining',
              ),
              const SizedBox(height: 6),
              const Text(
                'Resets every January 1st',
                style: TextStyle(color: AppColors.accent, fontSize: 11),
              ),
              const SizedBox(height: 20),
              // Year dot preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$year dot calendar — 365 dots',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    _YearDotGrid(daysPassed: daysPassed),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Set as Wallpaper →',
                onPressed: () async {
                  await ref
                      .read(appSettingsProvider.notifier)
                      .setCalendarType(CalendarType.year);
                  if (!context.mounted) return;
                  context.go('${AppRoutes.wallpaperPreview}?from=${AppRoutes.yearPreview}');
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearDotGrid extends StatelessWidget {
  final int daysPassed;
  const _YearDotGrid({required this.daysPassed});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, box) {
      const dotSize = 5.5;
      const spacing = 3.0;
      const step = dotSize + spacing;
      const total = 365;
      final cols = (box.maxWidth / step).floor();
      if (cols == 0) return const SizedBox.shrink();
      final rows = (total / cols).ceil();
      final height = rows * step;

      return SizedBox(
        height: height,
        child: CustomPaint(
          painter: _YearDotPainter(daysPassed: daysPassed),
        ),
      );
    });
  }
}

class _YearDotPainter extends CustomPainter {
  final int daysPassed;
  _YearDotPainter({required this.daysPassed});

  @override
  void paint(Canvas canvas, Size size) {
    const dotSize = 5.5;
    const spacing = 3.0;
    const step = dotSize + spacing;
    const total = 365;
    final cols = (size.width / step).floor();
    if (cols == 0) return;
    const r = dotSize / 2;
    final livedP = Paint()..color = AppColors.dotLived;
    final todayP = Paint()..color = AppColors.dotToday;
    final futureP = Paint()..color = AppColors.dotFuture;

    for (int i = 0; i < total; i++) {
      final cx = (i % cols) * step + r;
      final cy = (i ~/ cols) * step + r;
      Paint p;
      if (i == daysPassed - 1) {
        p = todayP;
      } else if (i < daysPassed) {
        p = livedP;
      } else {
        p = futureP;
      }
      canvas.drawCircle(Offset(cx, cy), r, p);
    }
  }

  @override
  bool shouldRepaint(_YearDotPainter o) => o.daysPassed != daysPassed;
}
