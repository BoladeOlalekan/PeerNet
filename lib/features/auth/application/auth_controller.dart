import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:peer_net/features/AUTH/data/auth_repository.dart';
import 'package:peer_net/features/AUTH/data/otp_repository.dart';
import 'package:peer_net/features/AUTH/domain/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Tracks which step of the auth flow the user is in
enum AuthFlow {
  idle,
  sendingOtp,
  otpSent,
  verifyingOtp,
  authenticating,
  authenticated,
}

/// Wrapper for both user state and flow state
class AuthState {
  final AsyncValue<UserEntity?> user;
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
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthController(this._authRepository, this._otpRepository)
      : super(AuthState.initial()) {
    _init();
  }

  Future<void> _init() async {
    // Load cached user instantly
    final cachedUser = await _authRepository.loadCachedUser();
    if (cachedUser != null) {
      state = AuthState(
        user: AsyncValue.data(cachedUser),
        flow: AuthFlow.authenticated,
      );
    }

    // 2. Listen to FirebaseAuth state and hydrate
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser == null) {
        state = const AuthState(user: AsyncValue.data(null), flow: AuthFlow.idle);
      } else {
        // show loading while fetching fresh Firestore user
        state = AuthState(
          user: const AsyncValue.loading(),
          flow: AuthFlow.authenticated,
        );

        final userEntity = await _authRepository.fetchCurrentUser();
        if (userEntity != null) {
          state = AuthState(
            user: AsyncValue.data(userEntity),
            flow: AuthFlow.authenticated,
          );
        }
      }
    });
  }

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

  Future<void> resendOtp(String email) async {
    state = const AuthState(
      user: AsyncValue.loading(),
      flow: AuthFlow.sendingOtp,
    );

    try {
      final otp = _otpRepository.generateOtp();
      await _otpRepository.storeOtp(email, otp);
      await _otpRepository.sendOtpEmail(email, otp);

      state = const AuthState(
        user: AsyncValue.data(null),
        flow: AuthFlow.otpSent,
      );
    } catch (e, st) {
      state = AuthState(user: AsyncValue.error(e, st), flow: AuthFlow.idle);
    }
  }

  Future<void> _syncUserToSupabase({
    required String firebaseUid,
    required String email,
    required String name,
    required String nickname,
    required String level,
    required String department,
  }) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('users').upsert({
        'firebase_uid': firebaseUid,
        'email': email,
        'name': name,
        'nickname': nickname,
        'level': int.parse(level),
        'department': department,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to sync user to Supabase: $e');
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
    state = const AuthState(user: AsyncValue.loading(), flow: AuthFlow.verifyingOtp);
    try {
      final isValid = await _otpRepository.verifyOtp(email, enteredOtp);
      if (!isValid) throw Exception("Invalid or expired OTP");

      UserEntity? user;
      try {
        // Try to create a new account
        user = await _authRepository.createUser(
          email: email,
          password: password,
          name: name,
          nickname: nickname,
          level: level,
          department: department,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // If already exists, just sign in
          user = await _authRepository.signIn(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      if (user != null) {
        await _syncUserToSupabase(
          firebaseUid: user.firebaseUid,
          email: user.email,
          name: name,
          nickname: nickname,
          level: level,
          department: department,
        );
      }

      state =
          AuthState(user: AsyncValue.data(user), flow: AuthFlow.authenticated);
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
      flow: AuthFlow.authenticating,
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

  /// Step 4 → sign out
  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState(user: AsyncValue.data(null), flow: AuthFlow.idle);
  }
}
