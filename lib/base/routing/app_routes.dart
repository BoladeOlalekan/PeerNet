import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/features/PEERai/ai_screen.dart';
import 'package:peer_net/features/AUTH/data/auth_repository.dart';
import 'package:peer_net/features/AUTH/presentation/auth.dart';
import 'package:peer_net/features/AUTH/presentation/otp_verification_screen.dart';
import 'package:peer_net/features/CONNECT/connect_screen.dart';
import 'package:peer_net/features/COURSES/presentation/courses_screen.dart';
import 'package:peer_net/features/HOME/home_screen.dart';
import 'package:peer_net/features/ONBOARDING/presentation/onboarding_screen.dart';
import 'package:peer_net/features/PROFILE/edit_profile_screen.dart';
import 'package:peer_net/features/PROFILE/profile_screen.dart';
import 'package:peer_net/main.dart';
import 'package:fluentui_icons/fluentui_icons.dart';

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
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final showSignUp = extra?['showSignUp'] as bool? ?? true;
          return AuthScreen(showSignUp: showSignUp);
        },
      ),
      GoRoute(
        path: RouteNames.editProfile,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: RouteNames.otp,
        builder: (context, state) {
          final data = state.extra as Map<String, String>;

          return OtpVerificationScreen(
            email: data['email']!,
            password: data['password']!,
            name: data['name']!,
            nickname: data['nickname']!,
            level: data['level']!,
            department: data['department']!,
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
            ),
            child: Scaffold(
              body: navigationShell,
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: false,
                selectedItemColor: Color(0xFF1E3A8A),
                unselectedItemColor: Color(0xFF1E3A8A).withValues(alpha: 0.7),
                iconSize: 25,
                currentIndex: navigationShell.currentIndex,
                onTap: (index) {
                  navigationShell.goBranch(index);
                },
            
                items: const [
                  BottomNavigationBarItem(
                  icon: Icon(FluentSystemIcons.ic_fluent_home_regular),
                  activeIcon: Icon(FluentSystemIcons.ic_fluent_home_filled),
                  label: 'HOME',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FluentSystemIcons.ic_fluent_people_regular),
                    activeIcon: Icon(FluentSystemIcons.ic_fluent_people_filled),
                    label: 'CONNECT',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FluentSystemIcons.ic_fluent_book_formula_text_regular),
                    activeIcon: Icon(FluentSystemIcons.ic_fluent_book_formula_text_filled),
                    label: 'COURSES',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FluentSystemIcons.ic_fluent_bot_regular),
                    activeIcon: Icon(FluentSystemIcons.ic_fluent_bot_filled),
                    label: 'PEERai',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(FluentSystemIcons.ic_fluent_person_regular),
                    activeIcon: Icon(FluentSystemIcons.ic_fluent_person_filled),
                    label: 'ME',
                  ),
                ],
              ),
            ),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                builder: (context, state) => const HomeScreen(),
              )
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.connect,
                builder: (context, state) => const ConnectScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.courses,
                builder: (context, state) => const CoursesScreen(
                  department: 'Software Engineering',
                  level: 500,
                ),
              )
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.ai,
                builder: (context, state) => const AiScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.me,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],

    redirect: (context, state) {
      final prefs = ref.read(sharedPrefsProvider);
      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      final loggedIn = authRepository.isLoggedIn;

      final onOnboardingScreen = state.matchedLocation == RouteNames.onboarding;
      final onAuthScreen = state.matchedLocation == RouteNames.auth;
      final onOtpScreen = state.matchedLocation == RouteNames.otp;

      // First-time users → force onboarding
      if (!hasSeenOnboarding && !onOnboardingScreen) {
        return RouteNames.onboarding;
      }

      // Returning users not logged in → go to auth
      if (hasSeenOnboarding && !loggedIn && !onAuthScreen && !onOtpScreen) {
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
