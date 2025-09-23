import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/domain/otp_entity.dart';

final otpRepositoryProvider = Provider<OtpRepository>((ref) {
  return OtpRepository();
});

class OtpRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String generateOtp() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }

  Future<void> storeOtp(String email, String otp) async {
    final otpEntity = OtpEntity(
      email: email,
      otp: otp,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('otp_verifications').doc(email).set(otpEntity.toMap());
  }

  Future<void> sendOtpEmail(String email, String otp) async {
    final callable = _functions.httpsCallable('sendOtpEmail');
    await callable.call({'email': email, 'otp': otp});
  }

  Future<bool> verifyOtp(String email, String enteredOtp) async {
    final doc = await _firestore.collection('otp_verifications').doc(email).get();
    if (!doc.exists) return false;

    final data = doc.data()!;
    final storedOtp = data['otp'] as String;
    final createdAt = (data['createdAt'] as Timestamp).toDate();

    if (DateTime.now().difference(createdAt).inMinutes > 5) {
      await _firestore.collection('otp_verifications').doc(email).delete();
      return false;
    }

    if (storedOtp == enteredOtp) {
      await _firestore.collection('otp_verifications').doc(email).delete();
      return true;
    }
    return false;
  }
}
