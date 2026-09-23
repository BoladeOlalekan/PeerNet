import 'dart:ui';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/widgets/input_field.dart';
import 'package:peer_net/features/AUTH/application/auth_providers.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController currentPasswordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final FocusNode currentPasswordFocus = FocusNode();
  final FocusNode newPasswordFocus = FocusNode();
  final FocusNode confirmPasswordFocus = FocusNode();

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  bool _isLoading = false;
  String? _errorMessage;

  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    currentPasswordFocus.addListener(() => _onFocusChange(currentPasswordFocus));
    newPasswordFocus.addListener(() => _onFocusChange(newPasswordFocus));
    confirmPasswordFocus.addListener(() => _onFocusChange(confirmPasswordFocus));
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    currentPasswordFocus.dispose();
    newPasswordFocus.dispose();
    confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _onFocusChange(FocusNode node) {
    if (node.hasFocus) {
      _clearErrors();
    }
  }

  void _clearErrors() {
    if (_currentPasswordError != null ||
        _newPasswordError != null ||
        _confirmPasswordError != null ||
        _errorMessage != null) {
      setState(() {
        _currentPasswordError = null;
        _newPasswordError = null;
        _confirmPasswordError = null;
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
    if (errorStr.contains('wrong-password') || errorStr.contains('invalid-credential')) {
      return 'The current password you entered is incorrect.';
    }
    if (errorStr.contains('weak-password')) {
      return 'The new password must be stronger (at least 6 characters).';
    }
    if (errorStr.contains('too-many-requests')) {
      return 'Too many attempts. Please try again later.';
    }
    return 'Failed to change password. Please verify details and try again.';
  }

  Future<void> _submit() async {
    final currentPassword = currentPasswordController.text;
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    String? currentErr;
    String? newErr;
    String? confirmErr;

    if (currentPassword.isEmpty) {
      currentErr = "Enter your current password";
    }
    if (newPassword.isEmpty) {
      newErr = "Enter a new password";
    } else if (newPassword.length < 6) {
      newErr = "Must be at least 6 characters";
    }
    if (confirmPassword.isEmpty) {
      confirmErr = "Confirm your new password";
    } else if (confirmPassword != newPassword) {
      confirmErr = "Passwords do not match";
    }

    if (currentErr != null || newErr != null || confirmErr != null) {
      setState(() {
        _currentPasswordError = currentErr;
        _newPasswordError = newErr;
        _confirmPasswordError = confirmErr;
      });
      _formKey.currentState?.validate();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    try {
      await ref.read(authControllerProvider.notifier).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
              SizedBox(width: 12),
              Text(
                'Password updated successfully!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppStyles.accentColor,
          duration: const Duration(seconds: 3),
        ),
      );

      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _getFriendlyErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            FluentSystemIcons.ic_fluent_ios_arrow_left_filled,
            color: AppStyles.headingColor,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          "Change Password",
          style: AppStyles.pageTitle.copyWith(fontSize: 20),
        ),
        titleSpacing: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        // Lock shield icon badge
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppStyles.primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppStyles.primaryColor.withValues(alpha: 0.1),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.lock_person_rounded,
                              color: AppStyles.primaryColor,
                              size: 50,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Form Container Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppStyles.inputBorder),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Current Password
                              InputField(
                                controller: currentPasswordController,
                                focusNode: currentPasswordFocus,
                                onChanged: (_) => _clearErrors(),
                                onTap: _clearErrors,
                                label: "CURRENT PASSWORD",
                                hint: "Enter current password",
                                errMsg: "Enter current password",
                                obscureText: !_showCurrentPassword,
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: AppStyles.iconMuted,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() {
                                    _showCurrentPassword = !_showCurrentPassword;
                                  }),
                                  icon: Icon(
                                    _showCurrentPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: AppStyles.iconMuted,
                                    size: 20,
                                  ),
                                ),
                                validator: (_) => _currentPasswordError,
                              ),
                              const SizedBox(height: 20),

                              // New Password
                              InputField(
                                controller: newPasswordController,
                                focusNode: newPasswordFocus,
                                onChanged: (_) => _clearErrors(),
                                onTap: _clearErrors,
                                label: "NEW PASSWORD",
                                hint: "Enter new password",
                                errMsg: "Enter new password",
                                obscureText: !_showNewPassword,
                                prefixIcon: const Icon(
                                  Icons.lock_open_rounded,
                                  color: AppStyles.iconMuted,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() {
                                    _showNewPassword = !_showNewPassword;
                                  }),
                                  icon: Icon(
                                    _showNewPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: AppStyles.iconMuted,
                                    size: 20,
                                  ),
                                ),
                                validator: (_) => _newPasswordError,
                              ),
                              const SizedBox(height: 20),

                              // Confirm Password
                              InputField(
                                controller: confirmPasswordController,
                                focusNode: confirmPasswordFocus,
                                onChanged: (_) => _clearErrors(),
                                onTap: _clearErrors,
                                label: "CONFIRM NEW PASSWORD",
                                hint: "Confirm new password",
                                errMsg: "Confirm new password",
                                obscureText: !_showConfirmPassword,
                                prefixIcon: const Icon(
                                  Icons.lock_clock_rounded,
                                  color: AppStyles.iconMuted,
                                  size: 20,
                                ),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() {
                                    _showConfirmPassword = !_showConfirmPassword;
                                  }),
                                  icon: Icon(
                                    _showConfirmPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: AppStyles.iconMuted,
                                    size: 20,
                                  ),
                                ),
                                validator: (_) => _confirmPasswordError,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppStyles.errorColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppStyles.errorColor.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: AppStyles.errorColor, size: 20),
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

                        // Save Password button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppStyles.primaryColor.withValues(alpha: 0.2),
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
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Save Password',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Montserrat',
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Loading blur overlay
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: AppStyles.backgroundColor.withValues(alpha: 0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
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
