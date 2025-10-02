import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/features/AUTH/domain/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  /// 🔹 Save user locally
  Future<void> _cacheUser(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_user', jsonEncode(user.toMap()));
  }

  /// 🔹 Load cached user (or null if none)
  Future<UserEntity?> loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('cached_user');
    if (jsonStr == null) return null;

    try {
      final map = jsonDecode(jsonStr);
      return UserEntity.fromMap(Map<String, dynamic>.from(map));
    } catch (_) {
      return null;
    }
  }

  /// 🔹 Clear cache (on logout)
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user');
  }

  Future<UserEntity?> createUser({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String level,
    required String department,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;

    if (user != null) {
      await user.updateDisplayName(name);

      final newUser = UserEntity(
        firebaseUid: user.uid,
        name: name,
        nickname: nickname,
        email: email,
        level: level,
        department: department,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(newUser.toMap());

      // ✅ cache after creation
      await _cacheUser(newUser);

      return newUser;
    }
    return null;
  }

  Future<UserEntity?> signIn({
    required String email,
    required String password,
  }) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final userEntity = UserEntity.fromMap(doc.data()!);

    // ✅ cache after sign in
    await _cacheUser(userEntity);

    return userEntity;
  }

  Future<UserEntity?> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final userEntity = UserEntity.fromMap(doc.data()!);

    // ✅ cache after fetching fresh data
    await _cacheUser(userEntity);

    return userEntity;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await clearCache(); // ✅ wipe cache
  }
}
