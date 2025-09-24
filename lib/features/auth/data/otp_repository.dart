import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/domain/otp_entity.dart';

final otpRepositoryProvider = Provider<OtpRepository>((ref) {
  return OtpRepository();
});

class OtpRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
    print("Sending OTP to $email with code $otp");

    final response = await http.post(
      Uri.parse('https://tfgvpremvcqdoqknnzei.functions.supabase.co/send-otp'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${dotenv.env['SUPABASE_ANON_KEY']}',
      },
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    print("Supabase response status: ${response.statusCode}");
    print("Supabase response body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Failed to send OTP email');
    }
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
