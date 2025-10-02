import 'dart:convert';

class UserEntity {
  final String firebaseUid;
  final String name;
  final String nickname;
  final String email;
  final String level;
  final String department;
  final DateTime createdAt;

  UserEntity({
    required this.firebaseUid,
    required this.name,
    required this.nickname,
    required this.email,
    required this.level,
    required this.department,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'firebase_uid': firebaseUid,
      'name': name,
      'nickname': nickname,
      'email': email,
      'level': level,
      'department': department,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      firebaseUid: map['firebase_uid'],
      name: map['name'],
      nickname: map['nickname'],
      email: map['email'],
      level: map['level'],
      department: map['department'], 
      createdAt: map['createdAt'] != null
      ? DateTime.tryParse(map['createdAt']) ?? 
      DateTime.now() : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());
  factory UserEntity.fromJson(String source) =>
  UserEntity.fromMap(json.decode(source));

  /// Copy with updated values
  UserEntity copyWith({
    String? firebaseUid,
    String? name,
    String? nickname,
    String? email,
    String? level,
    String? department,
    DateTime? createdAt,
  }) {
    return UserEntity(
      firebaseUid: firebaseUid ?? this.firebaseUid,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      level: level ?? this.level,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

