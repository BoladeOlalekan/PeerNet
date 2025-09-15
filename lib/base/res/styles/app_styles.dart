import 'package:flutter/material.dart';

Color primary = const Color(0xFF1E3A8A);

class AppStyles {
  static Color primaryColor = primary;
  static Color borderText = const Color(0xffffffff);
  static Color subText = Colors.black87;

  static TextStyle onboardstyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryColor,
    fontFamily: 'Montserrat',
  );

  static TextStyle subStyle = TextStyle(
    fontSize: 16,
    fontFamily: 'OpenSans',
    color: subText,
  );

  static ButtonStyle buttonsStyle1 = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    textStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Montserrat',
    ),
  );
}