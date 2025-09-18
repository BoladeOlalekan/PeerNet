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
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OtpEntity.fromMap(Map<String, dynamic> map) {
    return OtpEntity(
      email: map['email'],
      otp: map['otp'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
