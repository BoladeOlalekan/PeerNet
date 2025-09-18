import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/features/auth/application/auth_controller.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String password;
  final String name;
  final String level;
  final String department;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.password,
    required this.name,
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
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Enter the 4-digit code sent to your email"),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: "OTP"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                ref.read(authControllerProvider.notifier).verifyOtpAndCreateAccount(
                  email: widget.email,
                  password: widget.password,
                  name: widget.name,
                  level: widget.level,
                  department: widget.department,
                  enteredOtp: otpController.text.trim(),
                );
              },
              child: const Text("Verify"),
            ),
            if (authState.isLoading) const CircularProgressIndicator(),
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
