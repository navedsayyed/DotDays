import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/app_settings_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../services/date_service.dart';
import '../../routes/app_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final fmt = NumberFormat('#,###');

    // Stats for the hero
    final lifeTotal = DateService.totalDays(settings.lifespan);
    final yearLeft = DateService.daysRemainingInYear;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _BottomNav(
            // _tab 0 = Home (nav 0), _tab 1 = Settings (nav 2)
            current: _tab == 0 ? 0 : 2,
            onTap: (i) {
              if (i == 1) {
                // Go directly to wallpaper preview — no intermediate screen
                context.go(AppRoutes.wallpaperPreview);
              } else {
                setState(() => _tab = i == 2 ? 1 : 0);
              }
            },
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _tab == 0
              ? _HomeTab(settings: settings, fmt: fmt,
                  lifeTotal: lifeTotal, yearLeft: yearLeft)
              : _SettingsTabContent(settings: settings),
        ),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final dynamic settings;
  final NumberFormat fmt;
  final int lifeTotal;
  final int yearLeft;

  const _HomeTab({
    required this.settings, required this.fmt,
    required this.lifeTotal, required this.yearLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF12141A), Color(0xFF0D0F13)],
              ),
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HOME',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Every dot is one day.\nMake every day count.',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Track lifeee, year, and goals in one place.\nSet your wallpaper and stay focused every day.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _MetricCard(label: 'Life mode',
                        value: '${fmt.format(lifeTotal)} dots'),
                    const SizedBox(width: 10),
                    const _MetricCard(label: 'Year mode',
                        value: '365 dots'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Quick actions
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          _QuickAction(
            icon: Icons.calendar_today_outlined,
            title: 'Life Calendar',
            subtitle: 'View your life dots',
            onTap: () => context.go(AppRoutes.lifeStats),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.today_outlined,
            title: 'Year Calendar',
            subtitle: 'Days left in ${DateService.currentYear}',
            onTap: () => context.go(AppRoutes.yearPreview),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.flag_outlined,
            title: 'Goal Calendar',
            subtitle: 'Track your goal',
            onTap: () => context.go(AppRoutes.goalPreview),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  const _MetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textDim, fontSize: 10)),
            const SizedBox(height: 3),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.textDisabled, size: 13),
          ],
        ),
      ),
    );
  }
}

class _SetTab extends StatelessWidget {
  final dynamic settings;
  const _SetTab({required this.settings});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wallpaper, color: AppColors.accent, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Set Wallpaper',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate and apply your dot wallpaper',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: GestureDetector(
              onTap: () => context.go(AppRoutes.wallpaperPreview),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Preview Wallpaper →',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppColors.background,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTabContent extends ConsumerWidget {
  final dynamic settings;
  const _SettingsTabContent({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text(
            'Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          // Lifespan
          _SettingsTile(
            label: 'Expected lifespan',
            trailing: GestureDetector(
              onTap: () => _showLifespanDialog(context, ref, s.lifespan),
              child: Text(
                '${s.lifespan} yrs →',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          // Lived dot color
          _SettingsTile(
            label: 'Dot color (lived)',
            trailing: _DotColorRow(
              selectedColor: s.livedDotColor,
              onSelect: (c) => notifier.setLivedDotColor(c),
            ),
          ),
          // Today dot
          _SettingsTile(
            label: 'Today dot color',
            trailing: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Auto-update
          _SettingsTile(
            label: 'Auto-update wallpaper',
            trailing: _Toggle(
              value: s.autoUpdate,
              onChanged: (v) => notifier.setAutoUpdate(v),
            ),
          ),
          // Lock screen
          _SettingsTile(
            label: 'Show on lock screen',
            trailing: _Toggle(
              value: s.lockScreen,
              onChanged: (v) => notifier.setLockScreen(v),
            ),
          ),
          // Day counter
          _SettingsTile(
            label: 'Show day counter',
            trailing: _Toggle(
              value: s.showDayCounter,
              onChanged: (v) => notifier.setShowDayCounter(v),
            ),
          ),
          // Date of birth
          _SettingsTile(
            label: 'Date of birth',
            trailing: GestureDetector(
              onTap: () => context.go(AppRoutes.lifeInput),
              child: const Text(
                'Edit →',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            showBorder: false,
          ),
        ],
      ),
    );
  }

  void _showLifespanDialog(BuildContext context, WidgetRef ref, int current) {
    int temp = current;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setInner) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Expected Lifespan',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 17),
          ),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppColors.accent),
                onPressed: () {
                  if (temp > 50) setInner(() => temp--);
                },
              ),
              Text(
                '$temp years',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline,
                    color: AppColors.accent),
                onPressed: () {
                  if (temp < 120) setInner(() => temp++);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            TextButton(
              onPressed: () async {
                await ref
                    .read(appSettingsProvider.notifier)
                    .setLifespan(temp);
                if (context.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save',
                  style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String label;
  final Widget trailing;
  final bool showBorder;

  const _SettingsTile({
    required this.label,
    required this.trailing,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showBorder
            ? const Border(bottom: BorderSide(color: AppColors.border, width: 0.5))
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _DotColorRow extends StatelessWidget {
  final Color selectedColor;
  final ValueChanged<Color> onSelect;

  const _DotColorRow({required this.selectedColor, required this.onSelect});

  static const _colors = [
    Colors.white,
    Color(0xFFFF6B35),
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFE91E63),
    Color(0xFFFFEB3B),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: _colors.map((c) {
        final selected = c.value == selectedColor.value;
        return GestureDetector(
          onTap: () => onSelect(c),
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: AppColors.accent, width: 2)
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Home', 'Set', 'Settings'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1115),
        border: Border.all(color: AppColors.borderSubtle),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == current;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFF1A1F27)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textDim,
                    fontSize: 12,
                    fontWeight: active
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Clean minimal toggle — no ugly OS-default Switch colors.
class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 44,
        height: 26,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? AppColors.accent : const Color(0xFF2A2D35),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
