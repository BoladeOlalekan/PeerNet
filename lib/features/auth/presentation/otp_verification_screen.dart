import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
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
  ConsumerState<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Verify OTP",
              style: AppStyles.header1,
            ),
            
            SizedBox(height: 20,),

            Text("Enter the 6-digit code sent to your email"),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: "OTP"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(authControllerProvider.notifier).verifyOtpAndCreateAccount(
                  email: widget.email,
                  password: widget.password,
                  name: widget.name,
                  nickname: widget.nickname,
                  level: widget.level,
                  department: widget.department,
                  enteredOtp: otpController.text.trim(),
                );
              },
              child: const Text("Verify"),
            ),
            if (authState.isLoading) 
            const CircularProgressIndicator(),
            ?authState.whenOrNull(
              error: (e, _) => Text(e.toString(), style: const TextStyle(color: Colors.red)),
              data: (user) {
                if (user != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/home');
                    }
                  });
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
