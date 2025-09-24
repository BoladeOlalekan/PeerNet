import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/features/auth/application/auth_providers.dart';
import 'package:peer_net/features/auth/application/auth_controller.dart';

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

  @override
  Widget build(BuildContext context) {
    // 🔑 Listen for state changes
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (previous?.flow != next.flow &&
          next.flow == AuthFlow.authenticated) {
        // ✅ Navigate to home when authenticated
        context.go(RouteNames.home);
      }

      next.user.whenOrNull(
        error: (e, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        },
      );
    });

    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
            child: Column(
              children: [
                Text("Verify OTP", style: AppStyles.header1),
                const SizedBox(height: 10),
                const Text("Enter the 6-digit code sent to your email"),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: "OTP"),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: authState.user.isLoading
                      ? null
                      : () {
                          ref
                              .read(authControllerProvider.notifier)
                              .verifyOtpAndCreateAccount(
                                email: widget.email,
                                password: widget.password,
                                name: widget.name,
                                nickname: widget.nickname,
                                level: widget.level,
                                department: widget.department,
                                enteredOtp: otpController.text.trim(),
                              );
                        },
                  style: AppStyles.buttonsStyle1.copyWith(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 12),
                    ),
                  ),
                  child: const Text("Verify OTP",
                      style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 5),
                TextButton(
                  onPressed: () {
                    ref.read(authControllerProvider.notifier).resendOtp(widget.email);
                  },
                  child: const Text("Resend OTP"),
                ),
                if (authState.user.hasError)
                  Text(
                    authState.user.error.toString(),
                    style: const TextStyle(color: Colors.red),
                  ),
              ],
            ),
          ),
          if (authState.user.isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
