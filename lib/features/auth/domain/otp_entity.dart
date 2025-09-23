import 'package:cloud_firestore/cloud_firestore.dart';

class OtpEntity {
  final String email;
  final String otp;
  final DateTime createdAt;

  OtpEntity({
    required this.email,
    required this.otp,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'otp': otp,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory OtpEntity.fromMap(Map<String, dynamic> map) {
    return OtpEntity(
      email: map['email'],
      otp: map['otp'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}
