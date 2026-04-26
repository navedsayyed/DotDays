import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/models/calendar_type.dart';
import '../../shared/providers/app_settings_provider.dart';
import '../../shared/widgets/app_button.dart';
import '../../core/theme/app_colors.dart';
import '../../services/wallpaper_service.dart';
import '../../services/headless_wallpaper_renderer.dart';
import '../../services/storage_service.dart';
import '../../services/background_service.dart';
import '../../routes/app_router.dart';
import '../wallpaper/wallpaper_canvas.dart';

class WallpaperPreviewScreen extends ConsumerStatefulWidget {
  final String? from;
  const WallpaperPreviewScreen({super.key, this.from});

  @override
  ConsumerState<WallpaperPreviewScreen> createState() =>
      _WallpaperPreviewScreenState();
}

class _WallpaperPreviewScreenState
    extends ConsumerState<WallpaperPreviewScreen> {
  final _boundaryKey = GlobalKey();
  late int _selectedLocation;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = StorageService.getWallpaperLocation();
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    // Capture BEFORE modifying — determines where to go after apply
    final wasAlreadySetup = ref.read(appSettingsProvider).onboardingComplete;
    bool success = false;
    String? errorMsg;
    try {
      // Use the same HeadlessWallpaperRenderer used by the background task
      // so the wallpaper looks identical on initial set and daily auto-update.
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
      final ok = await WallpaperService.applyWallpaper(file, _selectedLocation);
      if (ok) {
        // Save wallpaper location so background task can re-apply to same screen
        await StorageService.setWallpaperLocation(_selectedLocation);
        if (settings.autoUpdate) await BackgroundService.scheduleDaily();
        await ref
            .read(appSettingsProvider.notifier)
            .setOnboardingComplete(true);
        success = true;
      } else {
        errorMsg = 'Could not apply wallpaper. Try saving manually.';
      }
    } catch (e) {
      errorMsg = e.toString();
    } finally {
      if (mounted) setState(() => _applying = false);
    }
    if (!mounted) return;
    if (success) {
      // First time → success screen. Returning user → straight home.
      context.go(wasAlreadySetup ? AppRoutes.home : AppRoutes.success);
    } else if (errorMsg != null) {
      _showError(errorMsg);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content:
            Text(msg, style: const TextStyle(color: AppColors.textPrimary)),
      ),
    );
  }

  void _handleBack() {
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(appSettingsProvider);

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
                onTap: _handleBack,
                child: const Icon(Icons.arrow_back_ios_new,
                    color: AppColors.textMuted, size: 18),
              ),
              const SizedBox(height: 16),
              const Text(
                'Wallpaper preview',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              // Phone mockup preview
              Expanded(
                child: Center(
                  child: _PhoneMockup(
                    boundaryKey: _boundaryKey,
                    settings: settings,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Screen selector
              _ScreenSelector(
                selected: _selectedLocation,
                onChanged: (v) => setState(() => _selectedLocation = v),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Apply Wallpaper →',
                loading: _applying,
                onPressed: _apply,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhoneMockup extends StatelessWidget {
  final GlobalKey boundaryKey;
  final dynamic settings;

  const _PhoneMockup({required this.boundaryKey, required this.settings});

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final mockH = screenH * 0.42;
    final mockW = mockH * (9 / 19.5);

    return Container(
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
          child: RepaintBoundary(
            key: boundaryKey,
            child: WallpaperCanvas(settings: settings),
          ),
        ),
      ),
    );
  }
}

class _ScreenSelector extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _ScreenSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      (WallpaperService.locationLockScreen, 'Lock Screen'),
      (WallpaperService.locationHomeScreen, 'Home Screen'),
      (WallpaperService.locationBothScreens, 'Both'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: options.mapIndexed((idx, opt) {
          final isActive = selected == opt.$1;
          return GestureDetector(
            onTap: () => onChanged(opt.$1),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                      color: isActive ? AppColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isActive ? AppColors.accent : AppColors.textMuted,
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
                      color:
                          isActive ? AppColors.accent : AppColors.textDisabled,
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

extension<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int index, T item) f) {
    return asMap().entries.map((e) => f(e.key, e.value)).toList();
  }
}
