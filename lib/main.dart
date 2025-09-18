import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/app_routes.dart';
import 'package:peer_net/features/auth/presentation/auth.dart';
import 'package:peer_net/features/home/home_screen.dart';
import 'package:peer_net/features/onboarding/presentation/onboarding_screen.dart';
import 'package:peer_net/firebase_options.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(ProviderScope(child: MainApp(),));
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // make status bar see-through
      statusBarIconBrightness: Brightness.light, // for light or dark icons
    )
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(),
      routes: {
        AppRoutes.authScreen: (context) => const AuthScreen(),
        AppRoutes.homeScreen: (context) => const HomeScreen()
      },
    );
  }
}
