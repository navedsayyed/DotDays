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

class LifeInputScreen extends ConsumerStatefulWidget {
  const LifeInputScreen({super.key});

  @override
  ConsumerState<LifeInputScreen> createState() => _LifeInputScreenState();
}

class _LifeInputScreenState extends ConsumerState<LifeInputScreen> {
  DateTime? _dob;
  int _lifespan = 80;
  String _gender = 'Male';

  static const Map<String, int> _genderLifespan = {
    'Male': 76,
    'Female': 81,
    'Other': 79,
  };

  @override
  void initState() {
    super.initState();
    // Pre-fill with saved settings if available
    final settings = ref.read(appSettingsProvider);
    if (settings.dateOfBirth != null) {
      _dob = settings.dateOfBirth;
    }
    if (settings.lifespan > 0) {
      _lifespan = settings.lifespan;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            onPrimary: AppColors.textPrimary,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ), dialogTheme: const DialogThemeData(backgroundColor: AppColors.surface),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _setGender(String g) {
    setState(() {
      _gender = g;
      _lifespan = _genderLifespan[g] ?? 79;
    });
  }

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
              const KickerLabel('LIFE CALENDAR'),
              const SizedBox(height: 8),
              const Text(
                'When were\nyou born?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'All data stays on device',
                style: TextStyle(color: AppColors.textDisabled, fontSize: 12),
              ),
              const SizedBox(height: 28),
              // DOB
              InputCard(
                label: 'DATE OF BIRTH',
                onTap: _pickDate,
                child: _dob == null
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
                    : Text(
                        DateService.formatDate(_dob!),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 16),
                      ),
              ),
              // Lifespan
              InputCard(
                label: 'EXPECTED LIFESPAN',
                child: Row(
                  children: [
                    Text(
                      '$_lifespan',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'years',
                      style: TextStyle(
                          color: AppColors.textHint, fontSize: 14),
                    ),
                    const Spacer(),
                    _LifespanControl(
                      value: _lifespan,
                      onChanged: (v) => setState(() => _lifespan = v),
                    ),
                  ],
                ),
              ),
              // Gender
              InputCard(
                label: 'GENDER (avg lifespan)',
                child: Row(
                  children: ['Male', 'Female', 'Other'].map((g) {
                    final active = _gender == g;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _setGender(g),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.accent
                                : const Color(0xFF232831),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Text(
                            g,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: active
                                  ? AppColors.textPrimary
                                  : AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Show My Life →',
                onPressed: _dob == null
                    ? null
                    : () async {
                        await ref
                            .read(appSettingsProvider.notifier)
                            .setDateOfBirth(_dob!);
                        await ref
                            .read(appSettingsProvider.notifier)
                            .setLifespan(_lifespan);
                        if (!context.mounted) return;
                        context.go(AppRoutes.lifeStats);
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

class _LifespanControl extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _LifespanControl({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _btn(Icons.remove, () {
          if (value > 50) onChanged(value - 1);
        }),
        const SizedBox(width: 4),
        _btn(Icons.add, () {
          if (value < 120) onChanged(value + 1);
        }),
      ],
    );
  }

  Widget _btn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: AppColors.textMuted, size: 14),
      ),
    );
  }
}
