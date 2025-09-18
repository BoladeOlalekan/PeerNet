import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/app_routes.dart';
import 'package:peer_net/base/media.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/features/auth/application/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}


class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool isSignUp = true;
  bool showPassword = false;
  bool showConfirmPassword = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
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

  final List<String> departments = [
    'Software Engineering',
  ];
  String? selectedDepartment;

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      if (isSignUp) {
        ref.read(authControllerProvider.notifier).signUpWithOtp(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
          name: nameController.text.trim(),
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
    final authState = ref.watch(authControllerProvider);
    bool hasNavigated = false;

    if (authState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    authState.whenOrNull(
      data: (user) {
        if (user != null && !hasNavigated) {
          hasNavigated = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                AppRoutes.homeScreen
              );
            }
          });
        }
      },
      error: (e, _) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      ),
    );

    return Scaffold(
      backgroundColor: AppStyles.borderText,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Image.asset(
                  AppMedia.logo,
                  scale: 4.5,
                ),

                SizedBox(height: 18),

                Text(
                  isSignUp ? "Create a\nnew account" : "Sign In",
                  textAlign: TextAlign.start,
                  style: AppStyles.header1,
                ),

                SizedBox(height: isSignUp ? 20 : 0),

                if (isSignUp) ...[
                  Text(
                    "Full Name", 
                    style: AppStyles.inputLabel
                  ),

                  SizedBox(height: 10),

                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: "John Doe",
                      hintStyle: AppStyles.hintStyle,
                      filled: true,
                      fillColor: AppStyles.backgroundColor,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    validator: (value) => value!.isEmpty ? "Enter your name" : null,
                  ),
                ],

                SizedBox(height: 20),

                Text(
                  "Student Email or ID", 
                  style: AppStyles.inputLabel
                ),

                SizedBox(height: 10),

                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "user@futa.edu.ng",
                    hintStyle: AppStyles.hintStyle,
                    filled: true,
                    fillColor: AppStyles.backgroundColor,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your email";
                    } else if (!futaEmailRegex.hasMatch(value)) {
                      return "Email must be a valid futa.edu.ng address";
                    } else {
                      return null;
                    }
                  }
                ),

                SizedBox(height: 20),

                Text(
                  "Password", 
                  style: AppStyles.inputLabel
                ),

                SizedBox(height: 10),

                TextFormField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  decoration: InputDecoration(
                    hintText: "Enter password",
                    hintStyle: AppStyles.hintStyle,
                    filled: true,
                    fillColor: AppStyles.backgroundColor,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    suffixIcon: IconButton(
                      onPressed: (){
                        setState(() {
                          showPassword = !showPassword;
                        });
                      }, 
                      icon: Icon(
                        showPassword ? Icons.visibility_off : Icons.visibility,
                        color: AppStyles.hintColor,
                      ),
                    )
                  ),
                  validator: (value) => value!.length < 6 ? "Password must be at least 6 characters" : null,
                ),

                SizedBox(height: 20),

                if (isSignUp) ...[
                  Text(
                    "Confirm Password", 
                    style: AppStyles.inputLabel
                  ),

                  SizedBox(height: 10,),

                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: !showConfirmPassword,
                    decoration: InputDecoration(
                      hintText: "Confirm password",
                      hintStyle: AppStyles.hintStyle,
                      filled: true,
                      fillColor: AppStyles.backgroundColor,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      suffixIcon: IconButton(
                        onPressed: (){
                          setState(() {
                            showConfirmPassword = !showConfirmPassword;
                          });
                        }, 
                        icon: Icon(
                          showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: AppStyles.hintColor,
                        ),
                      )
                    ),
                    validator: (value) => value != passwordController.text ? "Passwords do not match" : null,
                  ),

                  SizedBox(height: 20),

                  Text(
                    "Level", 
                    style: AppStyles.inputLabel
                  ),

                  SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: InputDecoration(
                      hintText: 'Select Level',
                      hintStyle: AppStyles.hintStyle,
                      filled: true,
                      fillColor: AppStyles.backgroundColor,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: levels.map((level) {
                      return DropdownMenuItem(
                        value: level,
                        child: Text(level),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedLevel = value),
                    validator: (value) => value == null ? 'Please select your level' : null,
                  ),

                  SizedBox(height: 20),

                  Text(
                    "Department", 
                    style: AppStyles.inputLabel
                  ),

                  SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    decoration: InputDecoration(
                      hintText: 'Choose Department',
                      hintStyle: AppStyles.hintStyle,
                      filled: true,
                      fillColor: AppStyles.backgroundColor,
                      border: OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    items: departments.map((department) {
                      return DropdownMenuItem(
                        value: department,
                        child: Text(department),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedDepartment = value),
                    validator: (value) => value == null ? 'Please select your department' : null,
                  ),
                ],

                SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: AppStyles.buttonsStyle2,
                    child: Text(
                      isSignUp ? "Sign Up" : "Sign In",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                SizedBox(height: 16),

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
                            ..onTap = () => setState(() => isSignUp = !isSignUp),
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
    );
  }
}
