import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:peer_net/features/auth/data/auth_repository.dart';
import 'package:peer_net/features/auth/data/otp_repository.dart';
import 'auth_controller.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>(
  (ref) => AuthController(
    ref.read(authRepositoryProvider),
    ref.read(otpRepositoryProvider),
  ),
);
