import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_widgets.dart';
import '../../shared/widgets/misc_widgets.dart';
import '../../core/theme/app_colors.dart';
import '../../services/date_service.dart';
import '../../routes/app_router.dart';

class GoalInputScreen extends ConsumerStatefulWidget {
  final String? from;
  const GoalInputScreen({super.key, this.from});

  @override
  ConsumerState<GoalInputScreen> createState() => _GoalInputScreenState();
}

class _GoalInputScreenState extends ConsumerState<GoalInputScreen> {
  final _nameController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Pre-fill with saved settings if available
    final settings = ref.read(appSettingsProvider);
    if (settings.goalName != null && settings.goalName!.isNotEmpty) {
      _nameController.text = settings.goalName!;
    }
    _startDate = settings.goalStart;
    _endDate = settings.goalEnd;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now().add(const Duration(days: 30)));
    final first = isStart ? DateTime(2000) : (_startDate ?? DateTime.now());
    final last = DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: AppColors.textPrimary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
          dialogTheme:
              const DialogThemeData(backgroundColor: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  int get _duration {
    if (_startDate == null || _endDate == null) return 0;
    return _endDate!.difference(_startDate!).inDays;
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty &&
      _startDate != null &&
      _endDate != null &&
      _endDate!.isAfter(_startDate!);

  @override
  Widget build(BuildContext context) {
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
                  if (widget.from != null && widget.from!.isNotEmpty) {
                    context.go(widget.from!);
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
              const Text(
                'Define your goal',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Set a name and date range',
                style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
              ),
              const SizedBox(height: 24),
              // Goal name field
              InputCard(
                label: 'GOAL NAME',
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 16),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'e.g. Marathon prep',
                    hintStyle:
                        TextStyle(color: AppColors.textDisabled, fontSize: 15),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              // Start date
              InputCard(
                label: 'START DATE',
                onTap: () => _pickDate(true),
                child: _startDate == null
                    ? RichText(
                        text: const TextSpan(children: [
                          TextSpan(
                              text: 'DD / MM / ',
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 16)),
                          TextSpan(
                              text: 'YYYY',
                              style: TextStyle(
                                  color: AppColors.accent, fontSize: 16)),
                        ]),
                      )
                    : Text(DateService.formatDate(_startDate!),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 16)),
              ),
              // End date
              InputCard(
                label: 'END DATE',
                onTap: () => _pickDate(false),
                child: _endDate == null
                    ? RichText(
                        text: const TextSpan(children: [
                          TextSpan(
                              text: 'DD / MM / ',
                              style: TextStyle(
                                  color: AppColors.textPrimary, fontSize: 16)),
                          TextSpan(
                              text: 'YYYY',
                              style: TextStyle(
                                  color: AppColors.accent, fontSize: 16)),
                        ]),
                      )
                    : Text(DateService.formatDate(_endDate!),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 16)),
              ),
              if (_duration > 0) ...[
                const SizedBox(height: 6),
                const Text('Duration',
                    style:
                        TextStyle(color: AppColors.textDisabled, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  '$_duration days',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const Spacer(),
              PrimaryButton(
                label: 'Preview Goal →',
                onPressed: !_isValid
                    ? null
                    : () async {
                        await ref.read(appSettingsProvider.notifier).setGoal(
                              name: _nameController.text.trim(),
                              start: _startDate!,
                              end: _endDate!,
                            );
                        if (!context.mounted) return;
                        context.go(AppRoutes.goalPreview);
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
