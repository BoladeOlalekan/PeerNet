class UserEntity {
  final String uid;
  final String name;
  final String email;
  final String level;
  final String department;

  UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    required this.level,
    required this.department,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
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
      email: map['email'],
      level: map['level'],
      department: map['department'],
    );
  }
}
