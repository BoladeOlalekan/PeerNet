import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/routing/route_names.dart';

class FlutterSplashScreen extends StatefulWidget {
  const FlutterSplashScreen({super.key});

  @override
  State<FlutterSplashScreen> createState() => _FlutterSplashScreenState();
}

class _FlutterSplashScreenState extends State<FlutterSplashScreen> {
  @override
  void initState() {
    super.initState();

    // Lock status bar style to match native splash
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    Future.delayed(const Duration(seconds: 2), () {
      context.pushReplacement(
        RouteNames.onboarding,
        extra: {'transition': 'fade'},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_logo.png',
              fit: BoxFit.cover,
            ),
          ),
          // Overlay logo animation
          Center(
            child: AnimatedOpacity(
              opacity: 1,
              duration: const Duration(seconds: 2),
              child: Image.asset(
                'assets/images/splash_logo.png',
                width: 150,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
