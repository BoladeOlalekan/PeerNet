// edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/features/AUTH/application/auth_providers.dart';
import 'package:peer_net/features/AUTH/data/auth_repository.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController nicknameController;
  File? _selectedImage;
  bool _isSaving = false;
  bool _isPicking = false;

  @override
  void initState() {
    super.initState();
    final authState = ref.read(authControllerProvider);
    final user = authState.user.value;

    nicknameController = TextEditingController(
      text: user?.nickname ?? user?.name ?? '',
    );
  }

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      debugPrint('Image pick failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not pick image')),
      );
    } finally {
      if (mounted) setState(() => _isPicking = false);
    }
  }

  Future<void> _saveChanges() async {
    final authRepo = ref.read(authRepositoryProvider);
    final authController = ref.read(authControllerProvider.notifier);
    final authState = ref.read(authControllerProvider);
    final user = authState.user.value;

    if (user == null) return;

    final newNickname = nicknameController.text.trim();
    final nicknameChanged = newNickname.isNotEmpty && newNickname != user.nickname;
    final imageChanged = _selectedImage != null;

    // If nothing changed, just pop
    if (!nicknameChanged && !imageChanged) {
      context.pop();
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedUser = await authRepo.updateUserProfile(
        uid: user.firebaseUid,
        nickname: nicknameChanged ? newNickname : null,
        avatarFile: imageChanged ? _selectedImage : null,
      );

      // If updateUserProfile returned null, show error; else refresh state
      if (updatedUser == null) {
        throw Exception('Failed to update profile. Try again.');
      }

      // Refresh Riverpod state so whole app picks up changes
      await authController.refreshUser();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user.value;

    // Show a simple loading / empty UI if user not loaded yet
    if (authState.user.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final currentAvatar = _selectedImage != null
        ? FileImage(_selectedImage!)
        : (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
            ? NetworkImage(user.avatarUrl!)
            : const AssetImage('assets/images/default_avatar.png'))
                as ImageProvider;

    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // === HEADER ===
            Container(
              height: 56,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 0.8),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    color: Colors.black87,
                    onPressed: () => context.pop(),
                  ),
                  const Text(
                    "Edit Profile",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // === MAIN CONTENT ===
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar section
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 65,
                              backgroundImage: currentAvatar,
                              backgroundColor: Colors.grey.shade100,
                            ),
                            GestureDetector(
                              onTap: _pickImage,
                              child: Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: AppStyles.primaryColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: _isPicking
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.photo_camera,
                                        color: Colors.white,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Change Photo
                        SizedBox(
                          height: 40,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: _pickImage,
                            child: const Text(
                              "Change Photo",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Nickname
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Nickname",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: nicknameController,
                              decoration: InputDecoration(
                                hintText: "Enter your nickname",
                                hintStyle: TextStyle(color: Colors.grey.shade500),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(
                                    color: AppStyles.primaryColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // === SAVE BUTTON ===
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300, width: 0.8),
                ),
                color: AppStyles.backgroundColor.withOpacity(0.9),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            "Save Changes",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
