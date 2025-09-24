import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/media.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/base/widgets/input_field.dart';
import 'package:peer_net/features/auth/application/auth_controller.dart';
import 'package:peer_net/features/auth/application/auth_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool isSignUp = true;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool hasNavigated = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final RegExp futaEmailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@futa\.edu\.ng$");

  final List<String> levels = [
    '100 Level',
    '200 Level',
    '300 Level',
    '400 Level',
    '500 Level',
  ];
  String? selectedLevel;

  final List<String> departments = ['Software Engineering'];
  String? selectedDepartment;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (isSignUp) {
        ref.read(authControllerProvider.notifier).signUpWithOtp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          name: nameController.text.trim(),
          nickname: nicknameController.text.trim(),
          level: selectedLevel!,
          department: selectedDepartment!,
        );
      } else {
        ref.read(authControllerProvider.notifier).signIn(
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
            SnackBar(content: Text(e.toString())),
          );
        },
      );
    });


    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppStyles.borderText,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 48,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(AppMedia.logo, scale: 5),
                    const SizedBox(height: 18),
                    Text(
                      isSignUp ? "Sign Up" : "Sign In",
                      textAlign: TextAlign.start,
                      style: AppStyles.header1,
                    ),
                    if (isSignUp) ...[
                      const SizedBox(height: 20),
                      InputField(
                        controller: nameController,
                        label: "Full Name",
                        hint: "John Doe",
                        errMsg: "Enter your full name",
                      ),
                      const SizedBox(height: 20),
                      InputField(
                        controller: nicknameController,
                        label: "Nickname",
                        hint: "e.g Johnny",
                        errMsg: "Enter your nickname",
                      ),
                    ],
                    const SizedBox(height: 20),
                    InputField(
                      controller: emailController,
                      label: "Student Email or ID",
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
                    const SizedBox(height: 20),
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
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: AppStyles.hintColor,
                        ),
                      ),
                    ),
                    if (!isSignUp) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: forgot password screen
                          },
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                    ],
                    if (isSignUp) ...[
                      const SizedBox(height: 20),
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
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppStyles.hintColor,
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
                      const SizedBox(height: 20),
                      DropdownField(
                        label: "Level",
                        hint: "Select Level",
                        items: levels,
                        value: selectedLevel,
                        onChanged: (value) =>
                            setState(() => selectedLevel = value),
                      ),
                      const SizedBox(height: 20),
                      DropdownField(
                        label: "Department",
                        hint: "Select Department",
                        items: departments,
                        value: selectedDepartment,
                        onChanged: (value) =>
                            setState(() => selectedDepartment = value),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: AppStyles.buttonsStyle2,
                        child: Text(
                          isSignUp ? "Sign Up" : "Sign In",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: RichText(
                        text: TextSpan(
                          style: AppStyles.subStyle2,
                          children: [
                            TextSpan(
                              text: isSignUp
                                  ? "Already have an account? "
                                  : "Don't have an account? ",
                            ),
                            TextSpan(
                              text: isSignUp ? "Sign In" : "Sign Up",
                              style: AppStyles.subLink,
                              recognizer: TapGestureRecognizer()
                                ..onTap = () =>
                                    setState(() => isSignUp = !isSignUp),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (authState.user.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }
}
