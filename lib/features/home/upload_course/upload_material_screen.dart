import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/features/AUTH/domain/user_entity.dart';
import 'package:peer_net/features/HOME/upload_course/upload_material_controller.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:peer_net/main.dart';

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
  List<Map<String, dynamic>> _courses = [];

  String? _selectedSemester;
  String? _selectedCourseId;
  String? _selectedFileType;
  File? _selectedFile;

  bool _loadingSemesters = true;

  int _parseLevel(String levelStr) {
    final digits = RegExp(r'\d+').stringMatch(levelStr);
    return digits != null ? int.parse(digits) : 100;
  }

  @override
  void initState() {
    super.initState();
    _fetchSemestersInBackground();
  }

  Future<void> _fetchSemestersInBackground() async {
    try {
      final level = _parseLevel(widget.currentUser.level);
      final semesters = await ref
          .read(uploadMaterialControllerProvider.notifier)
          .fetchSemesters(
            department: widget.currentUser.department,
            level: level,
          );

      if (mounted) {
        setState(() {
          _semesters = semesters;
          _loadingSemesters = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingSemesters = false);
      }
      debugPrint("Error fetching semesters: $e");
    }
  }

  Future<void> _loadCourses(String semester) async {
    setState(() => _courses = []);
    try {
      final level = _parseLevel(widget.currentUser.level);
      final data = await ref
          .read(uploadMaterialControllerProvider.notifier)
          .fetchCourses(
            department: widget.currentUser.department,
            level: level,
            semester: semester,
          );
      setState(() => _courses = data);
    } catch (e) {
      debugPrint("Error fetching courses: $e");
    }
  }

  Future<void> _pickFile() async {
    try {
      final file =
          await ref.read(uploadMaterialControllerProvider.notifier).pickFile();
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

    if (_selectedFile == null) {
      _showSnack('Please select a file');
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
      await ref.read(uploadMaterialControllerProvider.notifier).uploadMaterial(
        uploaderId: firebaseUser.uid,
        department: widget.currentUser.department,
        courseId: _selectedCourseId!,
        fileType: _selectedFileType!,
        file: _selectedFile!,
        level: _parseLevel(widget.currentUser.level),
        semester: _selectedSemester!,
        courseCode: courseCode,
      );

      // ✅ Trigger local notification after successful upload
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
        });
      }
    } catch (e) {
      _showSnack('Upload failed: $e');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadMaterialControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload File'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(FluentSystemIcons.ic_fluent_ios_arrow_left_filled),
          color: AppStyles.subText,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loadingSemesters
      ? const Center(child: CircularProgressIndicator())
      : Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildReadonlyField("Department", widget.currentUser.department),
                const SizedBox(height: 16),
                _buildReadonlyField("Level", widget.currentUser.level),
                const SizedBox(height: 16),

                // Semester Dropdown
                _buildDropdown(
                  value: _selectedSemester,
                  items: _semesters,
                  hint: 'Select Semester',
                  onChanged: (value) {
                    setState(() {
                      _selectedSemester = value;
                      _selectedCourseId = null;
                      if (value != null) _loadCourses(value);
                    });
                  },
                  validator: (v) =>
                      v == null ? 'Please select a semester' : null,
                ),
                const SizedBox(height: 16),

                // Course Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCourseId,
                  isExpanded: true,
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
                  decoration: InputDecoration(
                    hintText: 'Select Course',
                    hintStyle: AppStyles.hintStyle,
                    filled: true,
                    fillColor: AppStyles.backgroundColor,
                    border: OutlineInputBorder(
                      borderSide: BorderSide.none,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: (v) => v == null ? 'Please select a course' : null,
                ),

                const SizedBox(height: 16),

                // File Type Dropdown
                _buildDropdown(
                  value: _selectedFileType,
                  items: _fileTypes,
                  hint: 'Select File Type',
                  onChanged: (v) => setState(() => _selectedFileType = v),
                  validator: (v) =>
                      v == null ? 'Please select a file type' : null,
                ),
                const SizedBox(height: 16),

                // File Picker
                GestureDetector(
                  onTap: _pickFile,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 48),
                    decoration: BoxDecoration(
                      color: AppStyles.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            FluentSystemIcons.ic_fluent_folder_filled,
                            color: AppStyles.accentColor,
                            size: 35,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _selectedFile != null
                                  ? _selectedFile!.path.split('/').last
                                  : 'Select File',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedFile == null
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                TextButton.icon(
                  style: ButtonStyle(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                    backgroundColor: WidgetStateProperty.all(
                        AppStyles.primaryColor),
                    foregroundColor:
                        WidgetStateProperty.all(AppStyles.accentColor),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  onPressed: uploadState.isLoading ? null : _submit,
                  icon: uploadState.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          FluentSystemIcons.ic_fluent_upload_filled,
                          size: 18,
                          color: AppStyles.borderText,
                        ),
                  label: Text(
                    uploadState.isLoading ? 'Uploading...' : 'Submit',
                    style: AppStyles.editText.copyWith(
                      fontSize: 18,
                      color: AppStyles.borderText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildReadonlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.hintStyle.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          readOnly: true,
          initialValue: value,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppStyles.backgroundColor,
            border: OutlineInputBorder(
              borderSide: BorderSide.none,
              borderRadius: BorderRadius.circular(12),
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
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppStyles.hintStyle,
        filled: true,
        fillColor: AppStyles.backgroundColor,
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
    );
  }
}
