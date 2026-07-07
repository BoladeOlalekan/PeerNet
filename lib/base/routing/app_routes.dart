import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/base/widgets/notification/notification_page.dart';
import 'package:peer_net/base/widgets/notification/splash/flutter_splash_screen.dart';
import 'package:peer_net/features/auth/domain/user_entity.dart';
import 'package:peer_net/features/COURSES/models/course_model.dart';
import 'package:peer_net/features/COURSES/presentation/course_details_screen.dart';
import 'package:peer_net/features/home/upload_course/upload_material_screen.dart';
import 'package:peer_net/features/home/upload_course/upload_success_screen.dart';
import 'package:peer_net/features/PEERai/ai_screen.dart';
import 'package:peer_net/features/auth/data/auth_repository.dart';
import 'package:peer_net/features/auth/presentation/auth.dart';
import 'package:peer_net/features/auth/presentation/otp_verification_screen.dart';
import 'package:peer_net/features/CONNECT/connect_screen.dart';
import 'package:peer_net/features/COURSES/presentation/courses_screen.dart';
import 'package:peer_net/features/home/home_screen.dart';
import 'package:peer_net/features/onboarding/presentation/onboarding_screen.dart';
import 'package:peer_net/features/PROFILE/downloads_screen.dart';
import 'package:peer_net/features/PROFILE/edit_profile_screen.dart';
import 'package:peer_net/features/PROFILE/profile_screen.dart';
import 'package:peer_net/features/PROFILE/user_uploads_screen.dart';
import 'package:peer_net/main.dart';
import 'package:fluentui_icons/fluentui_icons.dart';

/// Helper for smooth transitions
CustomTransitionPage<dynamic> buildSlideTransitionPage({
  required GoRouterState state,
  required Widget child,
  Offset beginOffset = const Offset(0.1, 0), // default: slide from right
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      );
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  //final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      /// 🟦 Splash
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const FlutterSplashScreen(),
      ),

      /// 🟩 Onboarding
      GoRoute(
        path: RouteNames.onboarding,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const OnboardingScreen(),
        ),
      ),

      /// 🟨 Auth
      GoRoute(
        path: RouteNames.auth,
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final showSignUp = extra?['showSignUp'] as bool? ?? true;
          return buildSlideTransitionPage(
            state: state,
            child: AuthScreen(showSignUp: showSignUp),
          );
        },
      ),

      /// 🟧 OTP
      GoRoute(
        path: RouteNames.otp,
        pageBuilder: (context, state) {
          final data = state.extra as Map<String, String>;
          return buildSlideTransitionPage(
            state: state,
            beginOffset: const Offset(0, 0.1), // slide up
            child: OtpVerificationScreen(
              email: data['email']!,
              password: data['password']!,
              name: data['name']!,
              nickname: data['nickname']!,
              level: data['level']!,
              department: data['department']!,
            ),
          );
        },
      ),

      /// 🟪 Edit Profile
      GoRoute(
        path: RouteNames.editProfile,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const EditProfileScreen(),
        ),
      ),

      /// 🟦 Downloads
      GoRoute(
        path: RouteNames.downloads,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const DownloadsScreen(),
        ),
      ),

      /// 🟨 My Uploads
      GoRoute(
        path: RouteNames.myUploads,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const UserUploadsScreen(),
        ),
      ),

      /// 🔔 Notifications
      GoRoute(
        path: RouteNames.notifications,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const NotificationPage(),
        ),
      ),

      /// ⬆️ Upload Material
      GoRoute(
        path: RouteNames.uploads,
        pageBuilder: (context, state) {
          final user = state.extra as UserEntity;
          return buildSlideTransitionPage(
            state: state,
            beginOffset: const Offset(0, 0.1), // from bottom
            child: UploadMaterialScreen(currentUser: user),
          );
        },
      ),

      /// ✅ Upload Success
      GoRoute(
        path: RouteNames.thankYou,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const UploadSuccessScreen(),
        ),
      ),

      /// 📚 Course Details
      GoRoute(
        path: RouteNames.courseDetails,
        name: RouteNames.courseDetails,
        pageBuilder: (context, state) {
          final course = state.extra as CourseModel;
          return buildSlideTransitionPage(
            state: state,
            beginOffset: const Offset(0, 0.1),
            child: CourseDetailsScreen(course: course),
          );
        },
      ),

      /// 🏠 Bottom Navigation Shell
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
                selectedItemColor: const Color(0xFF1E3A8A),
                unselectedItemColor: const Color(
                  0xFF1E3A8A,
                ).withValues(alpha: 0.7),
                iconSize: 25,
                currentIndex: navigationShell.currentIndex,
                onTap: (index) => navigationShell.goBranch(index),
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
                    icon: Icon(
                      FluentSystemIcons.ic_fluent_book_formula_text_regular,
                    ),
                    activeIcon: Icon(
                      FluentSystemIcons.ic_fluent_book_formula_text_filled,
                    ),
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
          /// Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.home,
                pageBuilder: (context, state) => buildSlideTransitionPage(
                  state: state,
                  beginOffset: const Offset(-0.1, 0), // slide from left
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),

          /// Connect
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.connect,
                pageBuilder: (context, state) => buildSlideTransitionPage(
                  state: state,
                  child: const ConnectScreen(),
                ),
              ),
            ],
          ),

          /// Courses
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.courses,
                pageBuilder: (context, state) => buildSlideTransitionPage(
                  state: state,
                  child: const CoursesScreen(
                    department: 'Software Engineering',
                    level: 500,
                  ),
                ),
              ),
            ],
          ),

          /// AI
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.ai,
                pageBuilder: (context, state) => buildSlideTransitionPage(
                  state: state,
                  child: const AiScreen(),
                ),
              ),
            ],
          ),

          /// Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.me,
                pageBuilder: (context, state) => buildSlideTransitionPage(
                  state: state,
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],

    /// 🔁 Redirect logic (unchanged)
    redirect: (context, state) {
      final prefs = ref.read(sharedPrefsProvider);
      final authRepository = ref.watch(authRepositoryProvider);

      final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
      final loggedIn = authRepository.isLoggedIn;

      final onOnboardingScreen = state.matchedLocation == RouteNames.onboarding;
      final onAuthScreen = state.matchedLocation == RouteNames.auth;
      final onOtpScreen = state.matchedLocation == RouteNames.otp;
      final onSplashScreen = state.matchedLocation == RouteNames.splash;

      if (onSplashScreen) {
        return null; // Splash screen handles its own timed transition
      }

      if (!hasSeenOnboarding && !onOnboardingScreen) {
        return RouteNames.onboarding;
      }

      if (hasSeenOnboarding && !loggedIn && !onAuthScreen && !onOtpScreen) {
        return RouteNames.auth;
      }

      if (loggedIn && (onAuthScreen || onOnboardingScreen)) {
        return RouteNames.home;
      }

      return null;
    },
  );
});
