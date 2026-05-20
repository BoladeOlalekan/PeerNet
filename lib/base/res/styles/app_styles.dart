import 'package:flutter/material.dart';

Color primary = const Color(0xFF1E3A8A);
Color accent = const Color(0xFF10B981);

class AppStyles {
  // ─── Core palette ───────────────────────────────────────────────
  static Color primaryColor = primary;
  static Color accentColor = accent;
  static Color borderText = const Color(0xffffffff);
  static Color backgroundColor = const Color(0xFFF3F4F6);
  static Color hintColor = Colors.grey;
  static Color subText = Colors.black87;
  static Color labelText = const Color(0xFF8F92A1);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // ─── Extended palette (for modern UI) ───────────────────────────
  /// Dark heading color — near-black with a cool tint
  static const Color headingColor = Color(0xFF1A1D26);

  /// Muted body text — for subtitles and secondary info
  static const Color mutedText = Color(0xFF9CA3AF);

  /// Form label color — medium gray
  static const Color formLabel = Color(0xFF6B7280);

  /// Input field fill — very light gray
  static const Color inputFill = Color(0xFFF9FAFB);

  /// Input border — subtle gray
  static const Color inputBorder = Color(0xFFE5E7EB);

  /// Hint text inside inputs
  static const Color inputHint = Color(0xFFD1D5DB);

  /// Subtle icon color
  static const Color iconMuted = Color(0xFFBFC3CE);

  /// Error color
  static Color errorColor = const Color(0xFFEF4444);

  // ─── Text styles ────────────────────────────────────────────────
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
    color: accentColor,
  );

  static TextStyle header1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    color: subText,
    height: 1.2,
    fontFamily: 'Montserrat',
  );

  /// Large page heading — bold, tight tracking
  static const TextStyle pageTitle = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w800,
    color: headingColor,
    height: 1.15,
    fontFamily: 'Montserrat',
    letterSpacing: -0.8,
  );

  /// Subtitle beneath a page title
  static const TextStyle pageSubtitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: mutedText,
    fontFamily: 'OpenSans',
    letterSpacing: 0.1,
  );

  /// Compact label for form fields
  static const TextStyle formLabelStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: formLabel,
    fontFamily: 'OpenSans',
    letterSpacing: 0.3,
  );

  /// Text typed into inputs
  static const TextStyle inputTextStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: headingColor,
    fontFamily: 'OpenSans',
  );

  /// Hint text style for inputs
  static const TextStyle inputHintStyle = TextStyle(
    fontSize: 14,
    color: inputHint,
    fontFamily: 'OpenSans',
    fontWeight: FontWeight.w400,
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
    color: hintColor,
  );

  static TextStyle doubleText1 = TextStyle(
    fontSize: 24,
    fontFamily: 'OpenSans',
    fontWeight: FontWeight.bold,
    color: primary,
  );

  static TextStyle doubleText2 = TextStyle(
    fontSize: 16,
    fontFamily: 'OpenSans',
    fontWeight: FontWeight.w400,
    color: accent,
  );

  static TextStyle profileName = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: subText,
  );

  static TextStyle profileMail = TextStyle(fontSize: 14, color: labelText);

  static TextStyle editText = TextStyle(fontSize: 14, color: borderText);

  // ─── Button styles ──────────────────────────────────────────────
  static ButtonStyle buttonsStyle1 = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 12),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    textStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Montserrat',
    ),
  );

  static ButtonStyle buttonsStyle2 = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: 80, vertical: 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    textStyle: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: 'Montserrat',
    ),
  );

  static ButtonStyle editProfileButton = TextButton.styleFrom(
    backgroundColor: accentColor,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
  );

  /// Standard InputDecoration for text fields
  static InputDecoration inputDecoration({
    required String hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: inputHintStyle,
      filled: false,
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: inputBorder, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: primaryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: errorColor.withValues(alpha: 0.6),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: errorColor, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
