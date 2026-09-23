import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:peer_net/main.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/features/auth/presentation/otp_verification_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final initResults = await Future.wait([
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    ),
    SharedPreferences.getInstance(),
  ]);

  final prefs = initResults[2] as SharedPreferences;

  final notificationService = NotificationService();
  await notificationService.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notificationService),
      ],
      child: const DevApp(),
    ),
  );
}

final _devRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const OtpVerificationScreen(
        email: "test@example.com",
        password: "Password123",
        name: "Test User",
        nickname: "Tester",
        level: "500",
        department: "Software Engineering",
      ),
    ),
    GoRoute(
      path: RouteNames.home,
      builder: (context, state) => const Scaffold(
        body: Center(
          child: Text('Home Screen (Mocked in Dev Mode)'),
        ),
      ),
    ),
  ],
);

class DevApp extends StatelessWidget {
  const DevApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _devRouter,
    );
  }
}
