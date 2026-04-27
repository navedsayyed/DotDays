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
import '../features/settings/legal_screen.dart';

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
  static const String privacy = '/privacy';
  static const String terms = '/terms';
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
        builder: (context, state) => LifeInputScreen(
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: AppRoutes.lifeStats,
        builder: (context, state) => LifeStatsScreen(
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: AppRoutes.yearPreview,
        builder: (context, state) => YearPreviewScreen(
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: AppRoutes.goalInput,
        builder: (context, state) => GoalInputScreen(
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: AppRoutes.goalPreview,
        builder: (context, state) => GoalPreviewScreen(
          from: state.uri.queryParameters['from'],
        ),
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
        builder: (context, state) {
          final tabStr = state.uri.queryParameters['tab'];
          final tab = tabStr != null ? int.tryParse(tabStr) ?? 0 : 0;
          return HomeScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.changeType,
        builder: (context, state) => ChooseTypeScreen(
          fromHome: true,
          from: state.uri.queryParameters['from'],
        ),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const LegalScreen(
          title: 'Privacy Policy',
          content: 'DotDays is committed to protecting your privacy.\n\n'
              '1. Data Collection\n'
              'DotDays is a privacy-first application. All data you enter into the app '
              '(including your calendar type, date of birth, goal, and visual preferences) '
              'is stored locally on your device.\n\n'
              '2. Data Transmission\n'
              'We do not transmit, upload, or share your personal data with any third '
              'parties. The app does not require an internet connection to function.\n\n'
              '3. Third-party Services\n'
              'This application does not integrate with any third-party analytics or '
              'advertising trackers.\n\n'
              '4. Changes to This Policy\n'
              'If we decide to change our privacy policy, we will update the modified '
              'date below.\n\n'
              'Last modified: April 2026',
        ),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const LegalScreen(
          title: 'Terms of Service',
          content: 'By using DotDays, you agree to these terms.\n\n'
              '1. Use of the App\n'
              'DotDays is provided "as is", for your personal use. You may not distribute '
              'or commercially exploit the app without permission.\n\n'
              '2. User Data\n'
              'You are responsible for the data you input into the app. Because data is '
              'stored locally, we cannot recover it if your phone is lost or reset.\n\n'
              '3. Disclaimer of Warranties\n'
              'The app is provided on an "as is" and "as available" basis without any '
              'warranties of any kind. We do not guarantee that the app will be completely '
              'free of errors.\n\n'
              '4. Limitation of Liability\n'
              'In no event shall the developers be liable for any indirect, incidental, '
              'special, or consequential damages arising out of your use of the app.\n\n'
              'Last updated: April 2026',
        ),
      ),
    ],
  );
});
