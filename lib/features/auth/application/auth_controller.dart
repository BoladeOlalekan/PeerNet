import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:peer_net/features/auth/data/auth_repository.dart';
import 'package:peer_net/features/auth/data/otp_repository.dart';

/// Tracks which step of the auth flow the user is in
enum AuthFlow {
  idle,
  sendingOtp,
  otpSent,
  verifyingOtp,
  authenticated,
}

/// Wrapper for both user state and flow state
class AuthState {
  final AsyncValue<User?> user;
  final AuthFlow flow;

  const AuthState({
    required this.user,
    required this.flow,
  });

  factory AuthState.initial() =>
      const AuthState(user: AsyncValue.data(null), flow: AuthFlow.idle);
}

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final OtpRepository _otpRepository;

  AuthController(this._authRepository, this._otpRepository)
      : super(AuthState.initial());

  /// Step 1 → send OTP email
  Future<void> signUpWithOtp({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String level,
    required String department,
  }) async {
    state = const AuthState(
      user: AsyncValue.loading(),
      flow: AuthFlow.sendingOtp,
    );
    try {
      final otp = _otpRepository.generateOtp();
      await _otpRepository.storeOtp(email, otp);
      await _otpRepository.sendOtpEmail(email, otp);

      // ✅ OTP sent, notify UI
      state = const AuthState(
        user: AsyncValue.data(null),
        flow: AuthFlow.otpSent,
      );
    } catch (e, st) {
      state = AuthState(user: AsyncValue.error(e, st), flow: AuthFlow.idle);
    }
  }

  /// Step 2 → verify OTP then create user account
  Future<void> verifyOtpAndCreateAccount({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String level,
    required String department,
    required String enteredOtp,
  }) async {
    state = const AuthState(
      user: AsyncValue.loading(),
      flow: AuthFlow.verifyingOtp,
    );
    try {
      final isValid = await _otpRepository.verifyOtp(email, enteredOtp);
      if (!isValid) throw Exception("Invalid or expired OTP");

      final user = await _authRepository.createUser(
        email: email,
        password: password,
        name: name,
        nickname: nickname,
        level: level,
        department: department,
      );

      // ✅ Success → authenticated
      state = AuthState(user: AsyncValue.data(user), flow: AuthFlow.authenticated);
    } catch (e, st) {
      state = AuthState(user: AsyncValue.error(e, st), flow: AuthFlow.idle);
    }
  }

  /// Step 3 → normal email/password sign in
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthState(
      user: AsyncValue.loading(),
      flow: AuthFlow.idle,
    );
    try {
      final user = await _authRepository.signIn(
        email: email,
        password: password,
      );
      state = AuthState(user: AsyncValue.data(user), flow: AuthFlow.authenticated);
    } catch (e, st) {
      state = AuthState(user: AsyncValue.error(e, st), flow: AuthFlow.idle);
    }
  }

  // /// Optional → sign out
  // Future<void> signOut() async {
  //   await _authRepository.signOut();
  //   state = AuthState.initial();
  // }
}
