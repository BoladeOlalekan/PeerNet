import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:peer_net/features/auth/domain/user_entity.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  bool get isLoggedIn => _auth.currentUser != null;

  Future<UserEntity?> createUser({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String level,
    required String department
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = userCredential.user;
    
    if (user != null) {
      await user.updateDisplayName(name);

      final newUser = UserEntity(
        uid: user.uid,
        name: name,
        nickname: nickname,
        email: email,
        level: level,
        department: department,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(
        newUser.toMap()
      );

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

    return UserEntity.fromMap(doc.data()!);
  }

  Future<UserEntity?> fetchCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserEntity.fromMap(doc.data()!);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
