import 'dart:ui';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/widgets/input_field.dart';
import 'package:peer_net/features/AUTH/application/auth_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();

  final RegExp futaEmailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@futa\.edu\.ng$");

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  String? _emailValidationError;

  @override
  void initState() {
    super.initState();
    emailFocusNode.addListener(_onEmailFocusChange);
  }

  @override
  void dispose() {
    emailFocusNode.removeListener(_onEmailFocusChange);
    emailFocusNode.dispose();
    emailController.dispose();
    super.dispose();
  }

  void _onEmailFocusChange() {
    if (emailFocusNode.hasFocus) {
      _clearErrors();
    }
  }

  void _clearErrors() {
    if (_emailValidationError != null || _errorMessage != null) {
      setState(() {
        _emailValidationError = null;
        _errorMessage = null;
      });
      _formKey.currentState?.validate();
    }
  }

  String _getFriendlyErrorMessage(dynamic error) {
    if (error == null) return '';
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socketexception') ||
        errorStr.contains('network') ||
        errorStr.contains('connection')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (errorStr.contains('user-not-found') ||
        errorStr.contains('no user record')) {
      return 'No account found with this student email.';
    }
    if (errorStr.contains('invalid-email')) {
      return 'The email address is badly formatted.';
    }
    if (errorStr.contains('too-many-requests')) {
      return 'Too many requests. Please try again later.';
    }
    return 'Something went wrong. Please check the email and try again.';
  }

  Future<void> _submit() async {
    final value = emailController.text.trim();
    String? validationResult;
    if (value.isEmpty) {
      validationResult = "Please enter your email";
    } else if (!futaEmailRegex.hasMatch(value)) {
      validationResult = "Enter a valid FUTA email (e.g. user@futa.edu.ng)";
    }

    if (validationResult != null) {
      setState(() {
        _emailValidationError = validationResult;
      });
      _formKey.currentState?.validate();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emailValidationError = null;
    });

    try {
      final email = emailController.text.trim();
      await ref.read(authControllerProvider.notifier).sendPasswordReset(email);
      setState(() {
        _isLoading = false;
        _emailSent = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = _getFriendlyErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.borderText,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            FluentSystemIcons.ic_fluent_ios_arrow_left_filled,
            color: AppStyles.headingColor,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/auth', extra: {'showSignUp': false});
            }
          },
        ),
      ),
      body: Stack(
        children: [
          // Background accents
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _emailSent ? _buildSuccessView() : _buildFormView(),
            ),
          ),

          // Loading overlay
          if (_isLoading)
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

  Widget _buildFormView() {
    return SingleChildScrollView(
      key: const ValueKey('ForgotPasswordForm'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            // Lock reset icon badge
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppStyles.primaryColor.withValues(
                      alpha: 0.15,
                    ),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.lock_reset_rounded,
                  color: AppStyles.primaryColor,
                  size: 54,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Title
            Text(
              'Forgot Password?',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppStyles.headingColor,
                fontFamily: 'Montserrat',
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              "Please enter the email address associated with your account.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppStyles.formLabel,
                height: 1.5,
                fontFamily: 'OpenSans',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Email input field
            InputField(
              controller: emailController,
              focusNode: emailFocusNode,
              onChanged: (_) => _clearErrors(),
              onTap: _clearErrors,
              label: "Email Address",
              hint: "Enter your email",
              errMsg: "Please enter your email",
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppStyles.iconMuted,
                size: 20,
              ),
              validator: (value) => _emailValidationError,
            ),
            const SizedBox(height: 24),

            // Error message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppStyles.errorColor.withValues(
                    alpha: 0.08,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppStyles.errorColor.withValues(
                      alpha: 0.2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: AppStyles.errorColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: AppStyles.errorColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor,
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
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Send Reset Instructions',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Montserrat',
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return SingleChildScrollView(
      key: const ValueKey('ForgotPasswordSuccess'),
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Checkmark Icon badge
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppStyles.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppStyles.accentColor.withValues(
                    alpha: 0.15,
                  ),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.mark_email_read_rounded,
                color: AppStyles.accentColor,
                size: 48,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Success Title
          const Text(
            'Check Your Email',
            style: AppStyles.pageTitle,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Success Description
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppStyles.pageSubtitle.copyWith(
                height: 1.6,
                fontSize: 15,
              ),
              children: [
                const TextSpan(
                  text:
                      "We have successfully sent a password reset link to\n",
                ),
                TextSpan(
                  text: emailController.text.trim(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppStyles.primaryColor,
                  ),
                ),
                const TextSpan(
                  text:
                      ".\n\nPlease check your inbox and follow the instructions to secure your account.",
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Back to Login Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/auth', extra: {'showSignUp': false});
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Back to Sign In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Try another email option
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Didn't get the email? ",
                style: TextStyle(
                  color: AppStyles.formLabel,
                  fontSize: 14,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _emailSent = false;
                  });
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  "Try another email",
                  style: TextStyle(
                    color: AppStyles.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
