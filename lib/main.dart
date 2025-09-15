import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:peer_net/pages/onboarding/onboarding_screen.dart';

void main() {
  runApp(const MainApp());
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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen(),
    );
  }
}
