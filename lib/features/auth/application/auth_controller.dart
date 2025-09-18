import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:peer_net/features/auth/data/auth_repository.dart';
import 'package:peer_net/features/auth/data/otp_repository.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>(
  (ref) => AuthController(
    ref.read(authRepositoryProvider),
    ref.read(otpRepositoryProvider),
  ),
);

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _authRepository;
  final OtpRepository _otpRepository;

  AuthController(this._authRepository, this._otpRepository) 
  : super(const AsyncValue.data(null));

  //SEND OTP
  Future<void> signUpWithOtp({
    required String email,
    required String password,
    required String name,
    required String level,
    required String department
  }) async {
    state = const AsyncValue.loading();
    try {
      final otp = _otpRepository.generateOtp();
      await _otpRepository.storeOtp(email, otp); 
      await _otpRepository.sendOtpEmail(email, otp); 
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  //VERIFY OTP
  Future<void> verifyOtpAndCreateAccount({
    required String email,
    required String password,
    required String name,
    required String level,
    required String department,
    required String enteredOtp,
  }) async {
    state = const AsyncValue.loading();
    try {
      final isValid = await _otpRepository.verifyOtp(email, enteredOtp);
      if (!isValid) throw Exception("Invalid or expired OTP");

      final user = await _authRepository.createUser(
        email: email,
        password: password,
        name: name,
        level: level,
        department: department,
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  //SIGN IN
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password
      );
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

}

