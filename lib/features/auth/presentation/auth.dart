import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/base/widgets/input_field.dart';
import 'package:peer_net/features/auth/application/auth_controller.dart';
import 'package:peer_net/features/auth/application/auth_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class AuthScreen extends ConsumerStatefulWidget {
  final bool showSignUp;
  const AuthScreen({this.showSignUp = true, super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late bool isSignUp;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool hasNavigated = false;

  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    isSignUp = widget.showSignUp;
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController!,
      curve: Curves.easeInOut,
    );
    _fadeController!.forward();
    _fetchDepartments();
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    nameController.dispose();
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final RegExp futaEmailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@futa\.edu\.ng$");

  final List<String> levels = [
    '100 Level',
    '200 Level',
    '300 Level',
    '400 Level',
    '500 Level',
  ];
  String? selectedLevel;

  List<String> departments = ['Software Engineering'];
  String? selectedDepartment;

  Future<void> _fetchDepartments() async {
    try {
      final response = await Supabase.instance.client
          .from('departments')
          .select('name')
          .order('name');
      final List<String> fetched = (response as List)
          .map<String>((row) => row['name'] as String)
          .toList();
      if (mounted && fetched.isNotEmpty) {
        setState(() {
          departments = fetched;
        });
      }
    } catch (e) {
      debugPrint('Error fetching departments: $e');
    }
  }

  void _toggleMode() {
    _fadeController?.reverse().then((_) {
      setState(() => isSignUp = !isSignUp);
      _fadeController?.forward();
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (isSignUp) {
        ref
            .read(authControllerProvider.notifier)
            .signUpWithOtp(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
              name: nameController.text.trim(),
              nickname: nicknameController.text.trim(),
              level: selectedLevel!,
              department: selectedDepartment!,
            );
      } else {
        ref
            .read(authControllerProvider.notifier)
            .signIn(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.flow != next.flow) {
        if (next.flow == AuthFlow.otpSent) {
          context.go(
            RouteNames.otp,
            extra: {
              'email': emailController.text.trim(),
              'password': passwordController.text.trim(),
              'name': nameController.text.trim(),
              'nickname': nicknameController.text.trim(),
              'level': selectedLevel!,
              'department': selectedDepartment!,
            },
          );
        } else if (next.flow == AuthFlow.authenticated) {
          context.go(RouteNames.home);
        }
      }

      next.user.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: AppStyles.errorColor,
            ),
          );
        },
      );
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppStyles.borderText,
      body: Stack(
        children: [
          // Subtle decorative background elements
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppStyles.primaryColor.withValues(alpha: 0.06),
                    AppStyles.primaryColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppStyles.accentColor.withValues(alpha: 0.06),
                    AppStyles.accentColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isSignUp ? 28 : 40),

                      // Header
                      Text(
                        isSignUp ? 'Create Account' : 'Welcome Back',
                        style: AppStyles.pageTitle,
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        isSignUp
                            ? 'Join the platform'
                            : 'Sign in to continue',
                        style: AppStyles.pageSubtitle,
                      ),

                      const SizedBox(height: 16),

                      // Form fields
                      if (isSignUp) ...[
                        InputField(
                          controller: nameController,
                          label: "Full Name",
                          hint: "Mike Allen",
                          errMsg: "Enter your full name",
                        ),
                        const SizedBox(height: 16),
                        InputField(
                          controller: nicknameController,
                          label: "Nickname",
                          hint: "e.g Micky",
                          errMsg: "Enter your nickname",
                        ),
                        const SizedBox(height: 16),
                      ],

                      InputField(
                        controller: emailController,
                        label: "Student Email",
                        hint: "user@futa.edu.ng",
                        errMsg: "Please enter your email",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Please enter your email";
                          }
                          if (!futaEmailRegex.hasMatch(value)) {
                            return "Enter a valid futa.edu.ng email";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      InputField(
                        controller: passwordController,
                        label: "Password",
                        hint: "Enter password",
                        errMsg: "Enter your password",
                        obscureText: !showPassword,
                        minLength: 6,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              showPassword = !showPassword;
                            });
                          },
                          icon: Icon(
                            showPassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            color: AppStyles.iconMuted,
                            size: 20,
                          ),
                        ),
                      ),

                      if (!isSignUp) ...[
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: forgot password screen
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppStyles.accentColor,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                          ),
                        ),
                      ],

                      if (isSignUp) ...[
                        const SizedBox(height: 16),
                        InputField(
                          controller: confirmPasswordController,
                          label: "Confirm Password",
                          hint: "Confirm password",
                          errMsg: "Please confirm your password",
                          obscureText: !showConfirmPassword,
                          suffixIcon: IconButton(
                            onPressed: () => setState(() {
                              showConfirmPassword = !showConfirmPassword;
                            }),
                            icon: Icon(
                              showConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppStyles.iconMuted,
                              size: 20,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != passwordController.text) {
                              return 'Passwords don\'t match';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownField(
                          label: "Level",
                          hint: "Select Level",
                          items: levels,
                          value: selectedLevel,
                          onChanged: (value) =>
                              setState(() => selectedLevel = value),
                        ),
                        const SizedBox(height: 16),
                        DropdownField(
                          label: "Department",
                          hint: "Select Department",
                          items: departments,
                          value: selectedDepartment,
                          onChanged: (value) =>
                              setState(() => selectedDepartment = value),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Submit button with gradient
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppStyles.primaryColor,
                                AppStyles.primaryColor.withValues(alpha: 0.85),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppStyles.primaryColor.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              isSignUp ? 'Create Account' : 'Sign In',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Toggle sign in / sign up
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: AppStyles.pageSubtitle.copyWith(
                              fontSize: 14,
                            ),
                            children: [
                              TextSpan(
                                text: isSignUp
                                    ? 'Already have an account? '
                                    : 'Don\'t have an account? ',
                              ),
                              TextSpan(
                                text: isSignUp ? 'Sign In' : 'Sign Up',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppStyles.primaryColor,
                                  decoration: TextDecoration.none,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = _toggleMode,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay with blur
          if (authState.user.isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: AppStyles.borderText.withValues(alpha: 0.6),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppStyles.borderText,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppStyles.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
