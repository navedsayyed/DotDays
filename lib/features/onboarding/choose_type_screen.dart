import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/calendar_type.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../routes/app_router.dart';

class ChooseTypeScreen extends ConsumerStatefulWidget {
  final bool fromHome;
  final String? from;
  const ChooseTypeScreen({super.key, this.fromHome = false, this.from});

  @override
  ConsumerState<ChooseTypeScreen> createState() => _ChooseTypeScreenState();
}

class _ChooseTypeScreenState extends ConsumerState<ChooseTypeScreen> {
  late CalendarType _selected;

  @override
  void initState() {
    super.initState();
    _selected = ref.read(appSettingsProvider).calendarType;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 24),
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () {
                    context.pop();
                  },
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: AppColors.textMuted, size: 18),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose calendar type',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select how you want to track your days',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 28),
              _TypeOption(
                type: CalendarType.life,
                selected: _selected == CalendarType.life,
                subtitle: 'Visualize your entire life as dots',
                onTap: () => setState(() => _selected = CalendarType.life),
              ),
              const SizedBox(height: 10),
              _TypeOption(
                type: CalendarType.year,
                selected: _selected == CalendarType.year,
                subtitle: 'Track the current year\'s progress',
                onTap: () => setState(() => _selected = CalendarType.year),
              ),
              const SizedBox(height: 10),
              _TypeOption(
                type: CalendarType.goal,
                selected: _selected == CalendarType.goal,
                subtitle: 'Set a goal and count every day',
                onTap: () => setState(() => _selected = CalendarType.goal),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Continue →',
                onPressed: () async {
                  await ref
                      .read(appSettingsProvider.notifier)
                      .setCalendarType(_selected);
                  if (!context.mounted) return;
                  // Build the back-link for child screens:
                  // When fromHome, back should return to changeType (which returns to Set tab)
                  final String backRoute;
                  if (widget.fromHome) {
                    // Encode the full changeType URL with its own from param
                    final changeTypeUrl = widget.from != null
                        ? '${AppRoutes.changeType}?from=${Uri.encodeComponent(widget.from!)}'
                        : AppRoutes.changeType;
                    backRoute = changeTypeUrl;
                  } else {
                    backRoute = AppRoutes.chooseType;
                  }
                  final fromParam = Uri.encodeComponent(backRoute);

                  switch (_selected) {
                    case CalendarType.life:
                      // Skip DOB input if already saved
                      final settings = ref.read(appSettingsProvider);
                      if (settings.onboardingComplete &&
                          settings.dateOfBirth != null) {
                        context.push('${AppRoutes.lifeStats}?from=$fromParam');
                      } else {
                        context.push('${AppRoutes.lifeInput}?from=$fromParam');
                      }
                    case CalendarType.year:
                      context.push('${AppRoutes.yearPreview}?from=$fromParam');
                    case CalendarType.goal:
                      // Skip goal input if already saved
                      final goalSettings = ref.read(appSettingsProvider);
                      if (goalSettings.onboardingComplete &&
                          goalSettings.goalStart != null &&
                          goalSettings.goalEnd != null) {
                        context.push('${AppRoutes.goalPreview}?from=$fromParam');
                      } else {
                        context.push('${AppRoutes.goalInput}?from=$fromParam');
                      }
                  }
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

class _TypeOption extends StatelessWidget {
  final CalendarType type;
  final bool selected;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeOption({
    required this.type,
    required this.selected,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.textMuted,
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.label,
                  style: TextStyle(
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
