import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/features/auth/application/auth_controller.dart';
import 'package:peer_net/features/auth/application/auth_providers.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String password;
  final String name;
  final String nickname;
  final String level;
  final String department;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
    required this.nickname,
    required this.level,
    required this.department,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends ConsumerState<OtpVerificationScreen> {
  final otpController = TextEditingController();
  late final List<FocusNode> _focusNodes;
  late final List<TextEditingController> _controllers;

  // Resend Countdown Timer
  int _resendCountdown = 30;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(6, (_) => FocusNode());
    _controllers = List.generate(6, (_) => TextEditingController());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        setState(() {
          _canResend = true;
          _timer?.cancel();
        });
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  void _updateOtpController() {
    final otpString = _controllers.map((c) => c.text).join();
    otpController.text = otpString;
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
    _updateOtpController();
  }

  String _getFriendlyErrorMessage(dynamic error) {
    if (error == null) return '';
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('socketexception') ||
        errorStr.contains('network_error') ||
        errorStr.contains('failed host lookup') ||
        errorStr.contains('connection refused') ||
        errorStr.contains('handshake') ||
        errorStr.contains('timeout') ||
        errorStr.contains('http')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    if (errorStr.contains('invalid') ||
        errorStr.contains('incorrect') ||
        errorStr.contains('bad signature') ||
        errorStr.contains('otp_expired') ||
        errorStr.contains('expired') ||
        errorStr.contains('wrong')) {
      if (errorStr.contains('expired')) {
        return 'The verification code has expired. Please request a new one.';
      }
      return 'Invalid verification code. Please check and try again.';
    }

    if (errorStr.contains('too many requests') ||
        errorStr.contains('rate limit') ||
        errorStr.contains('over_limit') ||
        errorStr.contains('429')) {
      return 'Too many attempts. Please wait a few minutes before trying again.';
    }

    if (errorStr.contains('already exists') || errorStr.contains('unique_violation')) {
      return 'An account with this email already exists.';
    }

    return 'Something went wrong. Please check your details and try again.';
  }

  Widget _buildPinBox(int index) {
    return SizedBox(
      width: 46,
      height: 54,
      child: KeyboardListener(
        focusNode: FocusNode(skipTraversal: true),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_controllers[index].text.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
              _controllers[index - 1].clear();
              _updateOtpController();
            }
          }
        },
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          showCursor: false,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppStyles.headingColor,
          ),
          decoration: InputDecoration(
            counterText: "",
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppStyles.inputBorder, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppStyles.primaryColor, width: 2),
            ),
            fillColor: AppStyles.inputFill,
            filled: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) {
            if (val.length > 1) {
              final cleanVal = val.replaceAll(RegExp(r'\D'), '');
              if (cleanVal.length == 6 && index == 0) {
                for (int i = 0; i < 6; i++) {
                  _controllers[i].text = cleanVal[i];
                }
                _focusNodes[5].requestFocus();
                _updateOtpController();
                return;
              }

              _controllers[index].text = val.substring(val.length - 1);
              _controllers[index].selection = TextSelection.fromPosition(
                const TextPosition(offset: 1),
              );
            }
            _onOtpDigitChanged(index, _controllers[index].text);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔑 Listen for state changes
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.flow != next.flow &&
          next.flow == AuthFlow.authenticated) {
        // ✅ Navigate to home when authenticated
        context.go(RouteNames.home);
      }
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppStyles.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Verify OTP",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppStyles.headingColor,
            fontFamily: 'Montserrat',
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppStyles.headingColor,
            size: 20,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppStyles.pageSubtitle.copyWith(height: 1.5),
                    children: [
                      const TextSpan(text: "We have sent a 6-digit verification code to\n"),
                      TextSpan(
                        text: widget.email,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppStyles.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // OTP Digit Boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildPinBox(index)),
                ),
                const SizedBox(height: 40),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: authState.user.isLoading
                        ? null
                        : () {
                            final otp = otpController.text.trim();
                            if (otp.length < 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter the full 6-digit code"),
                                ),
                              );
                              return;
                            }
                            ref
                                .read(authControllerProvider.notifier)
                                .verifyOtpAndCreateAccount(
                                  email: widget.email,
                                  password: widget.password,
                                  name: widget.name,
                                  nickname: widget.nickname,
                                  level: widget.level,
                                  department: widget.department,
                                  enteredOtp: otp,
                                );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.primaryColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: authState.user.isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Text(
                            "Verify & Proceed",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resend Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _canResend
                          ? "Didn't receive the code? "
                          : "Resend code in ",
                      style: const TextStyle(
                        color: AppStyles.formLabel,
                        fontSize: 14,
                      ),
                    ),
                    _canResend
                        ? TextButton(
                            onPressed: () {
                              ref
                                  .read(authControllerProvider.notifier)
                                  .resendOtp(widget.email);
                              _startTimer();
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              "Resend OTP",
                              style: TextStyle(
                                color: AppStyles.primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          )
                        : Text(
                            "${_resendCountdown}s",
                            style: TextStyle(
                              color: AppStyles.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                  ],
                ),

                // Error Display
                if (authState.user.hasError) ...[
                  const SizedBox(height: 24),
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
                            _getFriendlyErrorMessage(authState.user.error),
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
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
