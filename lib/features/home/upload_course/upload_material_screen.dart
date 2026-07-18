import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/features/auth/domain/user_entity.dart';
import 'package:peer_net/features/home/upload_course/upload_material_controller.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:peer_net/main.dart';
import 'package:permission_handler/permission_handler.dart';

class UploadMaterialScreen extends ConsumerStatefulWidget {
  final UserEntity currentUser;

  const UploadMaterialScreen({super.key, required this.currentUser});

  @override
  ConsumerState<UploadMaterialScreen> createState() =>
      _UploadMaterialScreenState();
}

class _UploadMaterialScreenState extends ConsumerState<UploadMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> _fileTypes = ['Note', 'Video', 'Past Question'];

  List<String> _semesters = [];
  List<Map<String, dynamic>> _allCourses = [];
  List<Map<String, dynamic>> _courses = [];

  String? _selectedSemester;
  String? _selectedCourseId;
  String? _selectedFileType;
  File? _selectedFile;

  late final TextEditingController _youtubeUrlController;
  late final TextEditingController _videoTitleController;

  bool _loadingData = true;

  int _parseLevel(String levelStr) {
    final digits = RegExp(r'\d+').stringMatch(levelStr);
    return digits != null ? int.parse(digits) : 100;
  }

  @override
  void initState() {
    super.initState();
    _youtubeUrlController = TextEditingController();
    _videoTitleController = TextEditingController();
    _loadInitialData();
  }

  @override
  void dispose() {
    _youtubeUrlController.dispose();
    _videoTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      final level = _parseLevel(widget.currentUser.level);
      final courses = await ref
          .read(uploadMaterialControllerProvider.notifier)
          .fetchAllCoursesForUpload(
            department: widget.currentUser.department,
            level: level,
          );

      if (mounted) {
        setState(() {
          _allCourses = courses;
          // Dynamically extract and sort unique semesters
          _semesters = courses
              .map<String>((c) => c['semester'] as String)
              .toSet()
              .toList();
          _semesters.sort();
          _loadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
      }
      debugPrint("Error loading upload data: $e");
    }
  }

  void _onSemesterChanged(String? semester) {
    setState(() {
      _selectedSemester = semester;
      _selectedCourseId = null; // Reset course selection
      if (semester != null) {
        // Filter courses in-memory instantly
        _courses = _allCourses
            .where((course) => course['semester'] == semester)
            .toList();
      } else {
        _courses = [];
      }
    });
  }

  Future<bool> _requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isPermanentlyDenied) {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'Storage access is permanently denied. Please enable it in the app settings to select files.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  openAppSettings();
                },
                child: const Text('Settings'),
              ),
            ],
          ),
        );
      }
      return false;
    }

    PermissionStatus result = await Permission.storage.request();
    if (result.isGranted) {
      return true;
    }

    if (Platform.isAndroid) {
      if (mounted) {
        final bool? consent = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Access Files & Documents'),
            content: const Text(
              'PeerNet requests your permission to launch the device file manager so you can select a document. Do you want to proceed?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Proceed', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
        return consent ?? false;
      }
    }
    
    return false;
  }

  Future<void> _pickFile() async {
    final hasPermission = await _requestStoragePermission();
    if (!hasPermission) return;

    try {
      final file = await ref
          .read(uploadMaterialControllerProvider.notifier)
          .pickFile();
      if (file == null) return;

      final extension = file.path.split('.').last.toLowerCase();
      final allowedExtensions = {
        'note': ['pdf', 'docx', 'pptx', 'txt', 'xlsx', 'jpg', 'jpeg', 'png'],
        'video': ['mp4', 'mov', 'avi', 'mkv'],
        'past question': ['pdf', 'docx', 'pptx', 'jpg', 'jpeg', 'png'],
      };

      final selectedType = _selectedFileType?.toLowerCase();
      if (selectedType == null) {
        _showSnack('Please select a file type first');
        return;
      }

      if (!allowedExtensions[selectedType]!.contains(extension)) {
        _showSnack('Invalid file type for $_selectedFileType');
        return;
      }

      setState(() => _selectedFile = file);
    } catch (e) {
      _showSnack('Error picking file: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final isVideo = _selectedFileType == 'Video';

    if (!isVideo && _selectedFile == null) {
      _showSnack('Please select a file');
      return;
    }

    if (isVideo && _youtubeUrlController.text.trim().isEmpty) {
      _showSnack('Please enter a YouTube link');
      return;
    }

    if (_selectedCourseId == null ||
        _selectedFileType == null ||
        _selectedSemester == null) {
      _showSnack('Please fill all required fields');
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _showSnack('Firebase user not authenticated');
      return;
    }

    final selectedCourse = _courses.firstWhere(
      (course) => course['id'].toString() == _selectedCourseId!,
    );

    final courseCode = selectedCourse['course_code'] as String;

    try {
      await ref
          .read(uploadMaterialControllerProvider.notifier)
          .uploadMaterial(
            uploaderId: firebaseUser.uid,
            department: widget.currentUser.department,
            courseId: _selectedCourseId!,
            fileType: _selectedFileType!,
            file: isVideo ? null : _selectedFile,
            youtubeUrl: isVideo ? _youtubeUrlController.text.trim() : null,
            fileName: isVideo ? _videoTitleController.text.trim() : null,
            level: _parseLevel(widget.currentUser.level),
            semester: _selectedSemester!,
            courseCode: courseCode,
          );

      final notifier = ref.read(notificationServiceProvider);
      await notifier.showNotification(
        title: 'Upload Complete!',
        body: 'Your course material has been submitted for admin review.',
      );

      if (mounted) {
        context.push(RouteNames.thankYou);
        setState(() {
          _selectedFile = null;
          _selectedCourseId = null;
          _selectedFileType = null;
          _selectedSemester = null;
          _youtubeUrlController.clear();
          _videoTitleController.clear();
          _courses = [];
        });
      }
    } catch (e) {
      _showSnack('Upload failed: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildFormSkeleton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Department Label & Field
          Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),

          // Level Label & Field
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),

          // Semester Dropdown
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),

          // Course Dropdown
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),

          // File Type Dropdown
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 20),

          // File Picker Zone
          Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 28),

          // Submit Button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppStyles.headingColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          readOnly: true,
          initialValue: value,
          style: const TextStyle(color: AppStyles.mutedText, fontSize: 15),
          decoration: AppStyles.inputDecoration(hint: '').copyWith(
            filled: true,
            fillColor: Colors.grey.shade50,
            suffixIcon: const Icon(
              FluentSystemIcons.ic_fluent_lock_filled,
              color: AppStyles.iconMuted,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    required FormFieldValidator<String>? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
      style: AppStyles.inputTextStyle,
      decoration: AppStyles.inputDecoration(
        hint: hint,
      ).copyWith(filled: true, fillColor: Colors.white),
      validator: validator,
    );
  }

  Widget _buildCourseDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCourseId,
      isExpanded: true,
      style: AppStyles.inputTextStyle,
      items: _courses
          .map(
            (course) => DropdownMenuItem<String>(
              value: course['id'].toString(),
              child: Text(
                '${course['course_code']} - ${course['course_name']}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _selectedCourseId = v),
      decoration: AppStyles.inputDecoration(
        hint: 'Select Course',
      ).copyWith(filled: true, fillColor: Colors.white),
      validator: (v) => v == null ? 'Please select a course' : null,
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppStyles.inputBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppStyles.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                FluentSystemIcons.ic_fluent_folder_filled,
                color: AppStyles.accentColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFile != null ? 'File Selected' : 'Choose a file',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppStyles.headingColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedFile != null
                  ? _selectedFile!.path.split('/').last
                  : 'Tap to browse notes, videos, or Qs',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _selectedFile != null
                    ? AppStyles.accentColor
                    : AppStyles.mutedText,
                fontSize: 13,
                fontWeight: _selectedFile != null
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AsyncValue<void> uploadState) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppStyles.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        onPressed: uploadState.isLoading || _loadingData ? null : _submit,
        icon: uploadState.isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(FluentSystemIcons.ic_fluent_upload_filled, size: 20),
        label: Text(
          uploadState.isLoading ? 'Uploading...' : 'Submit Material',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadMaterialControllerProvider);

    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
        title: Text(
          'Upload File',
          style: AppStyles.pageTitle.copyWith(fontSize: 20),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(FluentSystemIcons.ic_fluent_ios_arrow_left_filled),
          color: AppStyles.headingColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppStyles.inputBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: _loadingData
                  ? _buildFormSkeleton()
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildReadonlyField(
                          "Department",
                          widget.currentUser.department,
                        ),
                        const SizedBox(height: 16),
                        _buildReadonlyField("Level", widget.currentUser.level),
                        const SizedBox(height: 16),

                        // Semester Dropdown
                        _buildDropdown(
                          value: _selectedSemester,
                          items: _semesters,
                          hint: 'Select Semester',
                          onChanged: _onSemesterChanged,
                          validator: (v) =>
                              v == null ? 'Please select a semester' : null,
                        ),
                        const SizedBox(height: 16),

                        // Course Dropdown
                        _buildCourseDropdown(),
                        const SizedBox(height: 16),

                        // File Type Dropdown
                        _buildDropdown(
                          value: _selectedFileType,
                          items: _fileTypes,
                          hint: 'Select File Type',
                          onChanged: (v) {
                            setState(() {
                              _selectedFileType = v;
                              if (v == 'Video') {
                                _selectedFile = null;
                              } else {
                                _youtubeUrlController.clear();
                                _videoTitleController.clear();
                              }
                            });
                          },
                          validator: (v) =>
                              v == null ? 'Please select a file type' : null,
                        ),
                        const SizedBox(height: 20),

                        // File Picker or Youtube inputs
                        if (_selectedFileType == 'Video') ...[
                          TextFormField(
                            controller: _videoTitleController,
                            style: AppStyles.inputTextStyle,
                            decoration: AppStyles.inputDecoration(
                              hint: 'Video Title (e.g. Intro to Algebra)',
                            ).copyWith(filled: true, fillColor: Colors.white),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter a video title'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _youtubeUrlController,
                            style: AppStyles.inputTextStyle,
                            decoration: AppStyles.inputDecoration(
                              hint: 'YouTube Link (e.g. https://youtube.com/...)',
                            ).copyWith(
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: const Icon(
                                FluentSystemIcons.ic_fluent_video_clip_regular,
                                color: AppStyles.iconMuted,
                                size: 20,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter a YouTube link';
                              }
                              final lowercase = v.toLowerCase();
                              if (!lowercase.contains('youtube.com') &&
                                  !lowercase.contains('youtu.be')) {
                                return 'Please enter a valid YouTube link';
                              }
                              return null;
                            },
                          ),
                        ] else ...[
                          _buildUploadZone(),
                        ],
                        const SizedBox(height: 28),

                        // Submit button
                        _buildSubmitButton(uploadState),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
