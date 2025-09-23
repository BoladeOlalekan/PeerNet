import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/features/auth/data/auth_repository.dart';
import 'package:peer_net/features/auth/presentation/auth.dart';
import 'package:peer_net/features/auth/presentation/otp_verification_screen.dart';
import 'package:peer_net/features/home/home_screen.dart';
import 'package:peer_net/features/onboarding/presentation/onboarding_screen.dart';
import 'package:peer_net/main.dart'; // for sharedPrefsProvider

final goRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: RouteNames.onboarding,
    routes: [
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (context, state) => const OtpVerificationScreen(
          email: '',
          password: '',
          name: '',
          level: '',
          department: '', 
          nickname: '',
        ),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final prefs = ref.read(sharedPrefsProvider);
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      final loggedIn = authRepository.isLoggedIn;

      final onOnboardingScreen = state.matchedLocation == RouteNames.onboarding;
      final onAuthScreen = state.matchedLocation == RouteNames.auth;

      // First-time users → force onboarding
      if (!hasSeenOnboarding && !onOnboardingScreen) {
        return RouteNames.onboarding;
      }

      // Returning users not logged in → go to auth
      if (hasSeenOnboarding && !loggedIn && !onAuthScreen) {
        return RouteNames.auth;
      }

      // Logged-in users on onboarding/auth → go home
      if (loggedIn && (onAuthScreen || onOnboardingScreen)) {
        return RouteNames.home;
      }

      return null;
    },
  );
});
