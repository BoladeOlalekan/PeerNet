
import 'package:flutter/material.dart';
import 'package:peer_net/app_routes.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      "image": "assets/images/peers.png",
      "title": "Connect with Peers",
      "subtitle": "Join forums, chat groups, and study together."
    },
    {
      "image": "assets/images/updated.png",
      "title": "Stay Updated",
      "subtitle": "Have all required resources."
    },
    {
      "image": "assets/images/assist.png",
      "title": "Smart Support",
      "subtitle": "Ask our AI assistant anything, anytime."
    },
  ];

  void _nextPage() {
    if (_currentPage < onboardingData.length - 1) {
      _controller.nextPage(
        duration: Duration(milliseconds: 300), 
        curve: Curves.ease
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.authScreen
      ); // Navigate to login/signup
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: onboardingData.length,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemBuilder: (context, index) => Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.65,
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Image.asset(
                        onboardingData[index]["image"]!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  Text(
                    onboardingData[index]["title"]!,
                    style: AppStyles.onboardstyle
                  ),

                  SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      onboardingData[index]["subtitle"]!,
                      textAlign: TextAlign.center,
                      style: AppStyles.subStyle
                    ),
                  ),
                ],
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(onboardingData.length, (index) => 
              Container(
                margin: EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 12 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.indigo : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            ),
          ),

          SizedBox(height: 20),

          ElevatedButton(
            onPressed: _nextPage,
            style: AppStyles.buttonsStyle1,
            child: Text(
              _currentPage == onboardingData.length - 1 ? "Get Started" : "Next",
              style: TextStyle(color: Colors.white),
            ),
          ),

          SizedBox(height: 40),
        ],
      ),
    );
  }
}