import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/providers/app_settings_provider.dart';

// Screen imports
import '../features/onboarding/welcome_screen.dart';
import '../features/onboarding/choose_type_screen.dart';
import '../features/life/life_input_screen.dart';
import '../features/life/life_stats_screen.dart';
import '../features/year/year_preview_screen.dart';
import '../features/goal/goal_input_screen.dart';
import '../features/goal/goal_preview_screen.dart';
import '../features/wallpaper/wallpaper_preview_screen.dart';
import '../features/onboarding/success_screen.dart';
import '../features/home/home_screen.dart';
import '../features/settings/settings_screen.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String chooseType = '/choose-type';
  static const String lifeInput = '/life-input';
  static const String lifeStats = '/life-stats';
  static const String yearPreview = '/year-preview';
  static const String goalInput = '/goal-input';
  static const String goalPreview = '/goal-preview';
  static const String wallpaperPreview = '/wallpaper-preview';
  static const String success = '/success';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String changeType = '/change-type';
}

// Stable router — created once, never re-created.
// The redirect only fires for the root '/' path to decide which initial
// screen to show. All other paths pass through freely, including
// every step of the onboarding flow.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // Only redirect from the root splash — everywhere else is free.
      if (location == AppRoutes.welcome) {
        final isComplete = ref.read(appSettingsProvider).onboardingComplete;
        if (isComplete) return AppRoutes.home;
      }

      return null; // No redirect — let navigation happen normally.
    },
    routes: [
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.chooseType,
        builder: (context, state) => const ChooseTypeScreen(),
      ),
      GoRoute(
        path: AppRoutes.lifeInput,
        builder: (context, state) => const LifeInputScreen(),
      ),
      GoRoute(
        path: AppRoutes.lifeStats,
        builder: (context, state) => const LifeStatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.yearPreview,
        builder: (context, state) => const YearPreviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.goalInput,
        builder: (context, state) => const GoalInputScreen(),
      ),
      GoRoute(
        path: AppRoutes.goalPreview,
        builder: (context, state) => const GoalPreviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.wallpaperPreview,
        builder: (context, state) => WallpaperPreviewScreen(
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: AppRoutes.success,
        builder: (context, state) => const SuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.changeType,
        builder: (context, state) => const ChooseTypeScreen(fromHome: true),
      ),
    ],
  );
});
