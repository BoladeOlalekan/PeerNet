// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:peer_net/features/AUTH/domain/user_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;


final authRepositoryProvider = riverpod.Provider<AuthRepository>((ref) {
  return AuthRepository(
    firebaseAuth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
    supabase: Supabase.instance.client,
  );
});

class AuthRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final SupabaseClient supabase;

  AuthRepository({
    required this.firebaseAuth,
    required this.firestore,
    required this.supabase,
  });

  bool get isLoggedIn => firebaseAuth.currentUser != null;

  // === CLOUDINARY CONFIG ===
  static const _cloudName = 'dewaejnbk';
  static const _uploadPreset = 'PeerNet';

  // 🧠 AUTH HELPERS
  User? get currentUser => firebaseAuth.currentUser;

  Future<UserEntity?> getCurrentUserProfile() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    final doc = await firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final userEntity = UserEntity.fromMap(data);
    await cacheUser(userEntity);
    return userEntity;
  }

  // ✅ PUBLIC cache methods (renamed for controller consistency)
  Future<void> cacheUser(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toMap()));
  }

  Future<UserEntity?> loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user');
    if (cached == null) return null;
    return UserEntity.fromMap(jsonDecode(cached));
  }

  // ☁️ PROFILE UPDATE HANDLER (WITH CLOUDINARY)
  Future<UserEntity?> updateUserProfile({
    required String uid,
    String? nickname,
    File? avatarFile,
  }) async {
    try {
      String? newAvatarUrl;

      // === STEP 1: UPLOAD TO CLOUDINARY (if avatar selected) ===
      if (avatarFile != null) {
        final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        );

        final uploadRequest = http.MultipartRequest('POST', uri)
          ..fields['upload_preset'] = _uploadPreset
          ..files.add(await http.MultipartFile.fromPath('file', avatarFile.path));

        final uploadResponse = await uploadRequest.send();
        final uploadResult = await http.Response.fromStream(uploadResponse);

        if (uploadResponse.statusCode == 200) {
          final responseData = jsonDecode(uploadResult.body);
          newAvatarUrl = responseData['secure_url'];
        } else {
          throw Exception('Cloudinary upload failed: ${uploadResult.body}');
        }
      }

      // === STEP 2: UPDATE FIRESTORE ===
      final userRef = firestore.collection('users').doc(uid);
      final updateData = <String, dynamic>{};
      if (nickname != null) updateData['nickname'] = nickname;
      if (newAvatarUrl != null) updateData['avatarUrl'] = newAvatarUrl;

      if (updateData.isNotEmpty) {
        await userRef.update(updateData);
      }

      // === STEP 3: UPDATE FIREBASE AUTH PROFILE ===
      final user = firebaseAuth.currentUser;
      if (user != null) {
        await user.updateDisplayName(nickname ?? user.displayName);
        if (newAvatarUrl != null) {
          await user.updatePhotoURL(newAvatarUrl);
        }
      }

      // === STEP 4: UPDATE SUPABASE TABLE (mirror) ===
      try {
        await supabase.from('users').update({
          if (nickname != null) 'nickname': nickname,
          if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
        }).eq('firebase_uid', uid);
      } catch (e) {
        print('Supabase update failed: $e');
      }

      // === STEP 5: GET LATEST USER DATA & CACHE ===
      final updatedDoc = await userRef.get();
      final updatedUser = UserEntity.fromMap(updatedDoc.data()!);
      await cacheUser(updatedUser);

      return updatedUser;
    } catch (e) {
      print('Error updating user profile: $e');
      return null;
    }
  }

  // 🔐 AUTHENTICATION METHODS

  // --- 1️⃣ Email + Password Sign Up ---
  Future<UserEntity?> createUser({
    required String email,
    required String password,
    required String name,
    required String nickname,
    required String level,
    required String department,
  }) async {
    try {
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      final userEntity = UserEntity(
        firebaseUid: uid,
        name: name,
        nickname: nickname,
        email: email,
        level: level,
        department: department,
        createdAt: DateTime.now(),
      );

      await firestore.collection('users').doc(uid).set(userEntity.toMap());
      await cacheUser(userEntity);

      await syncFirebaseToSupabase();
      return userEntity;
    } catch (e) {
      print('⚠️ Error creating user: $e');
      return null;
    }
  }

  // --- 2️⃣ Email + Password Sign In ---
  Future<UserEntity?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await syncFirebaseToSupabase();

      return await fetchCurrentUser();
    } catch (e) {
      print('⚠️ Error signing in: $e');
      return null;
    }
  }

  // --- 3️⃣ Fetch currently signed-in user's full profile ---
  Future<UserEntity?> fetchCurrentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;

    final doc = await firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    final entity = UserEntity.fromMap(doc.data()!);
    await cacheUser(entity);
    return entity;
  }

  //Sync Firebase user with Supabase
  Future<void> syncFirebaseToSupabase() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return;

    try {
      // Get Firebase ID token
      final firebaseToken = await user.getIdToken(true);

      // Read Supabase credentials from .env
      final supabaseUrl = dotenv.env['SUPABASE_URL']!;
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']!;

      // Call Supabase Auth REST API
      final url = Uri.parse('$supabaseUrl/auth/v1/token?grant_type=id_token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'apikey': supabaseAnonKey,
        },
        body: jsonEncode({
          'provider': 'firebase',
          'id_token': firebaseToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await Supabase.instance.client.auth.setSession(data['access_token']);
        print('✅ Supabase session created successfully!');
        print(data);
      } else {
        print('❌ Supabase login failed: ${response.body}');
      }
    } catch (e) {
      print('Error syncing Firebase → Supabase: $e');
    }
  }

  // 🔐 SIGN OUT
  Future<void> signOut() async {
    await firebaseAuth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
  }
}
