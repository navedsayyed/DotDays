import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/models/calendar_type.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/misc_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../services/date_service.dart';
import '../../routes/app_router.dart';

class LifeStatsScreen extends ConsumerWidget {
  const LifeStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final dob = settings.dateOfBirth;

    if (dob == null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => context.go(AppRoutes.lifeInput));
      return const Scaffold(backgroundColor: AppColors.background);
    }

    final lived = DateService.daysLived(dob);
    final remaining = DateService.daysRemaining(dob, settings.lifespan);
    final total = DateService.totalDays(settings.lifespan);
    final fmt = NumberFormat('#,###');

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
                onTap: () => context.go(AppRoutes.lifeInput),
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textMuted, size: 18),
              ),
              const SizedBox(height: 20),
              const KickerLabel('YOUR LIFE'),
              const SizedBox(height: 16),
              StatTile(label: 'Days lived', value: fmt.format(lived)),
              StatTile(label: 'Days remaining', value: fmt.format(remaining)),
              const SizedBox(height: 4),
              const Text(
                'Updates every day automatically',
                style: TextStyle(color: AppColors.textHint, fontSize: 11),
              ),
              const SizedBox(height: 20),
              // Dot grid preview — Expanded so it fills remaining space
              Expanded(
                child: Container(
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
                        'Life dots — ${fmt.format(total)} total',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: _MiniDotGrid(
                          lived: lived,
                          total: total,
                          livedColor: settings.livedDotColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Set as Wallpaper →',
                onPressed: () async {
                  await ref
                      .read(appSettingsProvider.notifier)
                      .setCalendarType(CalendarType.life);
                  if (!context.mounted) return;
                  context.go(AppRoutes.wallpaperPreview);
                },
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Change Settings',
                onPressed: () => context.go(AppRoutes.settings),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniDotGrid extends StatelessWidget {
  final int lived;
  final int total;
  final Color livedColor;

  const _MiniDotGrid(
      {required this.lived, required this.total, required this.livedColor});

  @override
  Widget build(BuildContext context) {
    // Cap to 2000 dots for performance in the preview card
    final previewTotal = total.clamp(0, 2000);
    final previewLived =
        total > 0 ? (lived * previewTotal / total).round().clamp(0, previewTotal) : 0;

    return LayoutBuilder(builder: (ctx, box) {
      // Use the full available space from the Expanded parent
      final w = box.maxWidth.isFinite ? box.maxWidth : 300.0;
      final h = box.maxHeight.isFinite ? box.maxHeight : 200.0;

      return CustomPaint(
        size: Size(w, h),
        painter: _MinDotPainter(
          total: previewTotal,
          lived: previewLived,
          livedColor: livedColor,
        ),
      );
    });
  }
}

class _MinDotPainter extends CustomPainter {
  final int total;
  final int lived;
  final Color livedColor;

  _MinDotPainter(
      {required this.total,
      required this.lived,
      required this.livedColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || total == 0) return;
    const dotSize = 4.0;
    const spacing = 2.5;
    const step = dotSize + spacing;
    final cols = (size.width / step).floor().clamp(1, 9999);
    const r = dotSize / 2;
    final livedP = Paint()..color = livedColor;
    final todayP = Paint()..color = AppColors.dotToday;
    final futureP = Paint()..color = AppColors.dotFuture;

    for (int i = 0; i < total; i++) {
      final cx = (i % cols) * step + r;
      final cy = (i ~/ cols) * step + r;
      if (cy + r > size.height) break; // don't draw outside canvas
      Paint p;
      if (i == lived - 1) {
        p = todayP;
      } else if (i < lived) {
        p = livedP;
      } else {
        p = futureP;
      }
      canvas.drawCircle(Offset(cx, cy), r, p);
    }
  }

  @override
  bool shouldRepaint(_MinDotPainter o) =>
      o.total != total || o.lived != lived || o.livedColor != livedColor;
}
