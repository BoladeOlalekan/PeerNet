import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/features/auth/application/auth_providers.dart';
import 'package:peer_net/features/auth/data/auth_repository.dart';
import 'package:permission_handler/permission_handler.dart';

enum FileAccessType { all, limited, denied }

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

  bool get _hasUnsavedChanges {
    final user = ref.read(authControllerProvider).user.value;
    final initialNickname = user?.nickname ?? user?.name ?? '';
    final nicknameChanged =
        nicknameController.text.trim() != initialNickname.trim();
    final imageChanged = _selectedImage != null;
    return nicknameChanged || imageChanged;
  }

  Future<bool?> _showDiscardWarningDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Discard Changes?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppStyles.errorColor,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  Future<FileAccessType> _requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.status;
    
    if (status.isGranted) {
      return FileAccessType.all;
    }
    
    if (status.isPermanentlyDenied) {
      if (mounted) {
        await showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFEF2F2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.settings_suggest_rounded,
                          size: 36,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Storage Permission Required',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Storage access is permanently denied. Please enable it in your device settings to select and upload photos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey.shade300),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: const Color(0xFFDC2626),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              openAppSettings();
                            },
                            child: const Text(
                              'Open Settings',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
      return FileAccessType.denied;
    }

    PermissionStatus result = await Permission.storage.request();
    if (result.isGranted) {
      return FileAccessType.all;
    }

    if (Platform.isAndroid) {
      if (mounted) {
        final FileAccessType? consent = await showModalBottomSheet<FileAccessType>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (context) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 38,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.perm_media_rounded,
                          size: 36,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Allow PeerNet to access photos?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'To change your profile photo, allow PeerNet access to your device photos.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFEFF6FF),
                        foregroundColor: const Color(0xFF1E3A8A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, FileAccessType.limited),
                      child: const Text(
                        'Allow limited access',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, FileAccessType.all),
                      child: const Text(
                        'Allow all',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade200),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, FileAccessType.denied),
                      child: Text(
                        "Don't allow",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
        return consent ?? FileAccessType.denied;
      }
    }
    
    return FileAccessType.denied;
  }

  Future<void> _pickImage() async {
    final access = await _requestStoragePermission();
    if (access == FileAccessType.denied) return;

    if (access == FileAccessType.limited && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Limited access: only selected photos will be shared.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() => _isPicking = true);
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked == null) return;

      // Let the user crop the picked image before using it
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        maxWidth: 1200,
        maxHeight: 1200,
        compressQuality: 85,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: AppStyles.primaryColor,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Crop Photo', aspectRatioLockEnabled: false),
        ],
      );

      if (cropped != null) {
        setState(() => _selectedImage = File(cropped.path));
      } else {
        // If user cancelled cropping, optionally keep the original picked image
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      debugPrint('Image pick/crop failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not pick or crop image')),
        );
      }
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
    final nicknameChanged =
        newNickname.isNotEmpty && newNickname != user.nickname;
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

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      context.pop();
    } catch (e) {
      debugPrint('Failed to save profile: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: ${e.toString()}')),
      );
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentAvatar = _selectedImage != null
        ? FileImage(_selectedImage!)
        : (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : const AssetImage('assets/images/default_avatar.png'))
              as ImageProvider;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await _showDiscardWarningDialog();
        if (discard == true) {
          if (!context.mounted) return;
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppStyles.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppStyles.backgroundColor,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Edit Profile",
            style: AppStyles.pageTitle.copyWith(fontSize: 20),
          ),
          leading: IconButton(
            icon: const Icon(FluentSystemIcons.ic_fluent_ios_arrow_left_filled),
            color: AppStyles.headingColor,
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // === MAIN CONTENT ===
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
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
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage: currentAvatar,
                                  backgroundColor: Colors.grey.shade100,
                                ),
                              ),
                              Positioned(
                                right: 2,
                                bottom: 2,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    height: 38,
                                    width: 38,
                                    decoration: BoxDecoration(
                                      color: AppStyles.accentColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.2,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: _isPicking
                                        ? const Padding(
                                            padding: EdgeInsets.all(9.0),
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            FluentSystemIcons
                                                .ic_fluent_camera_add_filled,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Change Photo Text Button
                          SizedBox(
                            height: 40,
                            child: TextButton(
                              style: AppStyles.editProfileButton,
                              onPressed: _pickImage,
                              child: Text(
                                "Change Photo",
                                style: AppStyles.editText,
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // Inputs Card Group
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppStyles.inputBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Nickname Section
                                Text(
                                  "NICKNAME",
                                  style: AppStyles.formLabelStyle.copyWith(
                                    fontSize: 12,
                                    color: AppStyles.labelText,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: nicknameController,
                                  style: AppStyles.inputTextStyle,
                                  decoration: AppStyles.inputDecoration(
                                    hint: "Enter your nickname",
                                    suffixIcon:
                                        ValueListenableBuilder<
                                          TextEditingValue
                                        >(
                                          valueListenable: nicknameController,
                                          builder: (context, value, child) {
                                            return value.text.isNotEmpty
                                                ? IconButton(
                                                    icon: const Icon(
                                                      Icons.clear_rounded,
                                                      size: 18,
                                                      color:
                                                          AppStyles.iconMuted,
                                                    ),
                                                    onPressed: () =>
                                                        nicknameController
                                                            .clear(),
                                                  )
                                                : const SizedBox.shrink();
                                          },
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Email Section (Read-only)
                                Text(
                                  "EMAIL ADDRESS",
                                  style: AppStyles.formLabelStyle.copyWith(
                                    fontSize: 12,
                                    color: AppStyles.labelText,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: TextEditingController(
                                    text: user?.email ?? "",
                                  ),
                                  style: AppStyles.inputTextStyle.copyWith(
                                    color: AppStyles.formLabel,
                                  ),
                                  readOnly: true,
                                  enabled: false,
                                  decoration:
                                      AppStyles.inputDecoration(
                                        hint: "No email address found",
                                        suffixIcon: const Padding(
                                          padding: EdgeInsets.only(right: 12),
                                          child: Icon(
                                            FluentSystemIcons
                                                .ic_fluent_lock_filled,
                                            size: 18,
                                            color: AppStyles.iconMuted,
                                          ),
                                        ),
                                      ).copyWith(
                                        fillColor: AppStyles.inputFill,
                                        filled: true,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // === SAVE BUTTON ===
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                decoration: const BoxDecoration(
                  color: AppStyles.white,
                  border: Border(
                    top: BorderSide(color: AppStyles.inputBorder, width: 1),
                  ),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppStyles.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
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
      ),
    );
  }
}
