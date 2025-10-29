import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:peer_net/features/AUTH/data/auth_repository.dart';
import 'package:peer_net/features/AUTH/data/cloudinary_repository.dart';
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
    // 1️⃣ Load cached user instantly
    final cachedUser = await _authRepository.loadCachedUser();
    if (cachedUser != null) {
      state = AuthState(
        user: AsyncValue.data(cachedUser),
        flow: AuthFlow.authenticated,
      );
    }

    // 2️⃣ Listen to FirebaseAuth state and hydrate
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

    print("🚀 Syncing user to Supabase...");
    print("   UID: $firebaseUid");
    print("   Email: $email");
    print("   Dept: $department | Level: $level");

    try {
      final response = await supabase.from('users').upsert({
        'firebase_uid': firebaseUid,
        'full_name': name,
        'email': email,
        'nickname': nickname,
        'level': int.tryParse(level.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        'department': department,
        'is_admin': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select();

      print("✅ Supabase response: $response");
    } catch (e, st) {
      print("❌ Supabase sync error: $e");
      print(st);
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

      await _syncUserToSupabase(
        firebaseUid: user!.firebaseUid,
        email: user.email,
        name: name,
        nickname: nickname,
        level: level,
        department: department,
      );

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

      if (user != null) {
        // 🔁 Ensure user exists in Supabase mirror
        await _syncUserToSupabase(
          firebaseUid: user.firebaseUid,
          email: user.email,
          name: user.name,
          nickname: user.nickname,
          level: user.level.toString(),
          department: user.department,
        );
      }

      state = AuthState(user: AsyncValue.data(user), flow: AuthFlow.authenticated);
    } catch (e, st) {
      state = AuthState(user: AsyncValue.error(e, st), flow: AuthFlow.idle);
    }
  }

  Future<void> refreshUser() async {
    final userEntity = await _authRepository.fetchCurrentUser();
    if (userEntity != null) {
      state = AuthState(user: AsyncValue.data(userEntity), flow: AuthFlow.authenticated);
    }
  }

  /// ✅ Updated to use `cacheUser()` (no underscore)
  Future<void> updateUserProfileImage(File imageFile) async {
    try {
      final user = state.user.value;
      if (user == null) throw Exception("No user is currently signed in.");

      // 1️⃣ Upload to Cloudinary
      final cloudinaryRepo = CloudinaryRepository();
      final imageUrl = await cloudinaryRepo.uploadUserImage(imageFile);

      // 2️⃣ Update Supabase
      final supabase = Supabase.instance.client;
      await supabase
          .from('users')
          .update({
            'image_url': imageUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('firebase_uid', user.firebaseUid);

      // 3️⃣ Update Firebase cache + Firestore
      final updatedUser = user.copyWith(avatarUrl: imageUrl);
      await _authRepository.cacheUser(updatedUser);

      // 4️⃣ Update local state
      state = AuthState(
        user: AsyncValue.data(updatedUser),
        flow: AuthFlow.authenticated,
      );
    } catch (e, st) {
      state = AuthState(user: AsyncValue.error(e, st), flow: AuthFlow.authenticated);
    }
  }

  /// Step 4 → sign out
  Future<void> signOut() async {
    await _authRepository.signOut();
    state = const AuthState(user: AsyncValue.data(null), flow: AuthFlow.idle);
  }
}
