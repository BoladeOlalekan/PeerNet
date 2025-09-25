class UserEntity {
  final String uid;
  final String name;
  final String nickname;
  final String email;
  final String level;
  final String department;
  final DateTime createdAt;

  UserEntity({
    required this.uid,
    required this.name,
    required this.nickname,
    required this.email,
    required this.level,
    required this.department,
    required this.createdAt
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'nickname': nickname,
      'email': email,
      'level': level,
      'department': department,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      uid: map['uid'],
      name: map['name'],
      nickname: map['nickname'],
      email: map['email'],
      level: map['level'],
      department: map['department'], 
      createdAt: map['createdAt'] != null
      ? DateTime.parse(map['createdAt'])
      : DateTime.now(),
    );
  }

  /// Copy with updated values
  UserEntity copyWith({
    String? uid,
    String? name,
    String? nickname,
    String? email,
    String? level,
    String? department,
    DateTime? createdAt,
  }) {
    return UserEntity(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      email: email ?? this.email,
      level: level ?? this.level,
      department: department ?? this.department,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

