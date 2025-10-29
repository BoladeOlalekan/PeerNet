import 'package:flutter/material.dart';

Color primary = const Color(0xFF1E3A8A);
Color accent = const Color(0xFF10B981);

class AppStyles {
  static Color primaryColor = primary;
  static Color accentColor = accent;
  static Color borderText = const Color(0xffffffff);
  static Color backgroundColor = const Color(0xFFF3F4F6);
  static Color hintColor = Colors.grey;
  static Color subText = Colors.black87;
  static Color labelText = const Color(0xFF8F92A1);

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

  static TextStyle subStyle2 = TextStyle(
    fontSize: 14,
    fontFamily: 'OpenSans',
    color: subText,
  );

  static TextStyle subLink = TextStyle(
    decoration: TextDecoration.none,
    fontWeight: FontWeight.bold,
    color: accentColor
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

  static ButtonStyle buttonsStyle2 = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    textStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Montserrat',
    ),
  );

  static TextStyle header1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w500,
    color: subText,
    height: 1.2,
    fontFamily: 'Montserrat',
  );

  static TextStyle inputLabel = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: labelText,
    fontFamily: 'Montserrat',
  );

  static TextStyle hintStyle = TextStyle(
    fontSize: 16,
    fontFamily: 'OpenSans',
    color: hintColor
  );

  static TextStyle doubleText1 = TextStyle(
    fontSize: 24,
    fontFamily: 'OpenSans',
    fontWeight: FontWeight.bold,
    color: primary
  );

  static TextStyle doubleText2 = TextStyle(
    fontSize: 16,
    fontFamily: 'OpenSans',
    fontWeight: FontWeight.w400,
    color: accent
  );

  static TextStyle profileName = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: subText
  );

  static TextStyle profileMail = TextStyle(
    fontSize: 14,
    color: labelText
  );

  static TextStyle editText = TextStyle(
    fontSize: 14,
    color: borderText
  );

  static ButtonStyle editProfileButton = TextButton.styleFrom(
    backgroundColor: accentColor,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
  );
}