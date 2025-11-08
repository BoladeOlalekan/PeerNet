import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
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

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ));
          context.go(RouteNames.onboarding);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppStyles.primaryColor,
      body: Container(
        alignment: Alignment.center,
        color: AppStyles.primaryColor,
        child: AnimatedOpacity(
          opacity: 1,
          duration: const Duration(seconds: 2),
          child: Image.asset(
            'assets/images/splash_logo.png',
            width: 180,
            fit: BoxFit.contain,
            scale: 2.0,
          ),
        ),
      ),
    );
  }
}
