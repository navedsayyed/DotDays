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

class GoalPreviewScreen extends ConsumerWidget {
  const GoalPreviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final goalName = settings.goalName ?? 'My Goal';
    final start = settings.goalStart;
    final end = settings.goalEnd;

    if (start == null || end == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go(AppRoutes.goalInput));
      return const Scaffold(backgroundColor: AppColors.background);
    }

    final total = DateService.goalTotal(start, end);
    final completed = DateService.goalPassed(start);
    final remaining = DateService.goalRemaining(start, end);
    final progress = DateService.goalProgress(start, end);
    final percent = (progress * 100).round();

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
              const KickerLabel('GOAL CALENDAR'),
              const SizedBox(height: 8),
              Text(
                goalName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              StatTile(label: 'Days completed', value: '$completed'),
              StatTile(label: 'Days remaining', value: '$remaining'),
              StatTile(label: 'Total days', value: '$total'),
              const SizedBox(height: 6),
              Text(
                '${DateService.formatDateShort(start)} → ${DateService.formatDateShort(end)}',
                style: const TextStyle(color: AppColors.accent, fontSize: 11),
              ),
              const SizedBox(height: 20),
              // Goal dot grid preview — 1 dot = 1 day, matching Year style
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
                      '$goalName — $total dots · $percent%',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    _GoalDotGrid(
                      total: total,
                      completed: completed,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Set as Wallpaper →',
                onPressed: () async {
                  await ref
                      .read(appSettingsProvider.notifier)
                      .setCalendarType(CalendarType.goal);
                  if (!context.mounted) return;
                  context.go('${AppRoutes.wallpaperPreview}?from=${AppRoutes.goalPreview}');
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

class _GoalDotGrid extends StatelessWidget {
  final int total;
  final int completed;
  const _GoalDotGrid({required this.total, required this.completed});

  @override
  Widget build(BuildContext context) {
    // Cap at 500 for preview but scale proportionally
    final capped = total.clamp(0, 500);
    final cappedCompleted = total > 0
        ? (completed * capped / total).round().clamp(0, capped)
        : 0;

    return LayoutBuilder(builder: (ctx, box) {
      const dotSize = 5.5;
      const spacing = 3.0;
      const step = dotSize + spacing;
      final cols = (box.maxWidth / step).floor();
      if (cols == 0) return const SizedBox.shrink();
      final rows = (capped / cols).ceil();
      final height = rows * step;

      return SizedBox(
        height: height,
        child: CustomPaint(
          painter: _GoalDotPainter(
              total: capped, completed: cappedCompleted),
        ),
      );
    });
  }
}

class _GoalDotPainter extends CustomPainter {
  final int total;
  final int completed;
  _GoalDotPainter({required this.total, required this.completed});

  @override
  void paint(Canvas canvas, Size size) {
    const dotSize = 5.5;
    const spacing = 3.0;
    const step = dotSize + spacing;
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
      if (i == completed - 1 && completed > 0) {
        p = todayP;
      } else if (i < completed) {
        p = livedP;
      } else {
        p = futureP;
      }
      canvas.drawCircle(Offset(cx, cy), r, p);
    }
  }

  @override
  bool shouldRepaint(_GoalDotPainter o) =>
      o.total != total || o.completed != completed;
}

