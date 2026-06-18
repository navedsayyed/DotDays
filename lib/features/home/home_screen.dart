import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/providers/app_settings_provider.dart';

import '../../core/theme/app_colors.dart';
import '../../services/date_service.dart';
import '../../services/wallpaper_service.dart';
import '../../services/headless_wallpaper_renderer.dart';
import '../../services/storage_service.dart';
import '../../services/background_service.dart';
import '../../routes/app_router.dart';
import '../../shared/widgets/app_button.dart';
import '../wallpaper/wallpaper_canvas.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const HomeScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _tab; // 0 = Home, 1 = Set, 2 = Settings
  final List<int> _tabHistory = [0];

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    if (_tab != 0) {
      _tabHistory.add(_tab);
    }
  }

  void _onTabTapped(int index) {
    if (_tab == index) return;
    setState(() {
      _tabHistory.remove(index);
      _tabHistory.add(index);
      _tab = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);
    final fmt = NumberFormat('#,###');

    // Stats for the hero
    final lifeTotal = DateService.totalDays(settings.lifespan);
    final yearLeft = DateService.daysRemainingInYear;

    return PopScope(
      canPop: _tabHistory.length <= 1,
      onPopInvoked: (didPop) {
        if (didPop) return;
        if (_tabHistory.length > 1) {
          setState(() {
            _tabHistory.removeLast();
            _tab = _tabHistory.last;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _BottomNav(
              current: _tab,
              onTap: _onTabTapped,
            ),
          ),
        ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: _tab == 0
              ? _HomeTab(
                  settings: settings,
                  fmt: fmt,
                  lifeTotal: lifeTotal,
                  yearLeft: yearLeft)
              : _tab == 1
                  ? _SetTab(settings: settings)
                  : _SettingsTabContent(settings: settings),
        ),
      ),
    ));
  }
}

class _HomeTab extends StatelessWidget {
  final dynamic settings;
  final NumberFormat fmt;
  final int lifeTotal;
  final int yearLeft;

  const _HomeTab({
    required this.settings,
    required this.fmt,
    required this.lifeTotal,
    required this.yearLeft,
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
                  'Track life, year, and goals in one place.\nSet your wallpaper and stay focused every day.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _MetricCard(
                        label: 'Life mode',
                        value: '${fmt.format(lifeTotal)} dots'),
                    const SizedBox(width: 10),
                    const _MetricCard(label: 'Year mode', value: '365 dots'),
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
            onTap: () => context.push(AppRoutes.lifeStats),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.today_outlined,
            title: 'Year Calendar',
            subtitle: 'Days left in ${DateService.currentYear}',
            onTap: () => context.push(AppRoutes.yearPreview),
          ),
          const SizedBox(height: 8),
          _QuickAction(
            icon: Icons.flag_outlined,
            title: 'Goal Calendar',
            subtitle: 'Track your goal',
            onTap: () => context.push(AppRoutes.goalPreview),
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
                style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
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
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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

class _SetTab extends ConsumerStatefulWidget {
  final dynamic settings;
  const _SetTab({required this.settings});

  @override
  ConsumerState<_SetTab> createState() => _SetTabState();
}

class _SetTabState extends ConsumerState<_SetTab> {
  late int _selectedLocation;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = StorageService.getWallpaperLocation();
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    String? errorMsg;
    bool success = false;
    try {
      final settings = ref.read(appSettingsProvider);
      final file = await HeadlessWallpaperRenderer.render(
        calendarType: settings.calendarType,
        dateOfBirth: settings.dateOfBirth,
        lifespan: settings.lifespan,
        goalName: settings.goalName,
        goalStart: settings.goalStart,
        goalEnd: settings.goalEnd,
        livedDotColor: settings.livedDotColor,
      );
      if (file == null) throw Exception('Failed to render wallpaper');
      final ok =
          await WallpaperService.applyWallpaper(file, _selectedLocation);
      if (ok) {
        await StorageService.setWallpaperLocation(_selectedLocation);
        if (settings.autoUpdate) await BackgroundService.scheduleDaily();
        success = true;
      } else {
        errorMsg = 'Could not apply wallpaper.';
      }
    } catch (e) {
      errorMsg = e.toString();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1A1F27),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 18),
              SizedBox(width: 10),
              Text('Wallpaper applied!',
                  style: TextStyle(color: AppColors.textPrimary)),
            ],
          ),
        ),
      );
    } else if (errorMsg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surface,
          content: Text(errorMsg,
              style: const TextStyle(color: AppColors.textPrimary)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final screenH = MediaQuery.of(context).size.height;
    final mockH = screenH * 0.42;
    final mockW = mockH * (9 / 19.5);

    final options = [
      (WallpaperService.locationLockScreen, 'Lock Screen'),
      (WallpaperService.locationHomeScreen, 'Home Screen'),
      (WallpaperService.locationBothScreens, 'Both'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title — same as preview screen
        Row(
          children: [
            const Expanded(
              child: Text(
                'Wallpaper preview',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Edit type button
            GestureDetector(
              onTap: () => context.push('${AppRoutes.changeType}?from=${Uri.encodeComponent('${AppRoutes.home}?tab=1')}'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      settings.calendarType.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.expand_more_rounded,
                        color: AppColors.textMuted, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Phone mockup preview — same as preview screen
        Expanded(
          child: Center(
            child: Container(
              width: mockW,
              height: mockH,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3A3A3C), Color(0xFF1C1C1E)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: WallpaperCanvas(settings: settings),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Screen selector — same as preview screen
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: options.asMap().entries.map((entry) {
              final idx = entry.key;
              final opt = entry.value;
              final isActive = _selectedLocation == opt.$1;
              return GestureDetector(
                onTap: () => setState(() => _selectedLocation = opt.$1),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: idx < options.length - 1
                        ? const Border(
                            bottom: BorderSide(color: AppColors.borderSubtle))
                        : null,
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? AppColors.accent
                                : AppColors.textMuted,
                            width: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          opt.$2,
                          style: TextStyle(
                            color: isActive
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        isActive ? 'Selected' : 'Select',
                        style: TextStyle(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.textDisabled,
                          fontSize: 11,
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),

        // Apply button — same as preview screen
        PrimaryButton(
          label: 'Apply Wallpaper →',
          loading: _applying,
          onPressed: _apply,
        ),
        const SizedBox(height: 16),
      ],
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${s.lifespan} yrs',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.accent),
                ],
              ),
            ),
          ),
          // Auto-update home screen
          _SettingsTile(
            label: 'Auto-update home screen',
            trailing: _Toggle(
              value: s.autoUpdateHome,
              onChanged: (v) => notifier.setAutoUpdateHome(v),
            ),
          ),
          // Auto-update lock screen
          _SettingsTile(
            label: 'Auto-update lock screen',
            trailing: _Toggle(
              value: s.autoUpdateLock,
              onChanged: (v) => notifier.setAutoUpdateLock(v),
            ),
          ),
          // Info tip about auto-update
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF141820),
              border: Border.all(color: const Color(0xFF2A2F3A)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    color: Color(0xFF6B7280), size: 16),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'If you set a wallpaper from Gallery, turn off auto-update '
                    'for that screen to keep it. DotDays updates at midnight.',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
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
              onTap: () => context.push(AppRoutes.lifeInput),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Edit',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.accent),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'LEGAL & ABOUT',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          // Privacy Policy
          _SettingsTile(
            label: 'Privacy Policy',
            trailing: GestureDetector(
              onTap: () => context.push(AppRoutes.privacy),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textMuted),
            ),
          ),
          // Terms of Service
          _SettingsTile(
            label: 'Terms of Service',
            showBorder: false,
            trailing: GestureDetector(
              onTap: () => context.push(AppRoutes.terms),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textMuted),
            ),
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
                await ref.read(appSettingsProvider.notifier).setLifespan(temp);
                if (context.mounted) Navigator.pop(ctx);
              },
              child:
                  const Text('Save', style: TextStyle(color: AppColors.accent)),
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
            ? const Border(
                bottom: BorderSide(color: AppColors.border, width: 0.5))
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

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.current, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.grid_view_rounded, label: 'Set'),
    (icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF101216),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(_items.length, (i) {
          final active = i == current;
          final item = _items[i];
          return GestureDetector(
            onTap: () => onTap(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: active ? 18 : 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF1E2228) : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 20,
                    color: active ? Colors.white : const Color(0xFF5A5E66),
                  ),
                  if (active) ...[
                    const SizedBox(width: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
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
