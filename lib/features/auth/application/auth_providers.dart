import 'package:flutter_riverpod/legacy.dart';
import 'package:peer_net/features/auth/data/auth_repository.dart';
import 'package:peer_net/features/auth/data/otp_repository.dart';
import 'auth_controller.dart';

final authControllerProvider =
  StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    ref.read(authRepositoryProvider),
    ref.read(otpRepositoryProvider),
  );
});

