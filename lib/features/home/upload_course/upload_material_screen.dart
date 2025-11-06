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

  bool _isLoading = true;
  int _parseLevel(String levelStr) {
    final digits = RegExp(r'\d+').stringMatch(levelStr);
    return digits != null ? int.parse(digits) : 100;
  }

  @override
  void initState() {
    super.initState();
    _loadSemesters();
  }

  Future<void> _loadSemesters() async {
    try {
      final level = _parseLevel(widget.currentUser.level);
      final semesters = await ref
          .read(uploadMaterialControllerProvider.notifier)
          .fetchSemesters(
            department: widget.currentUser.department,
            level: level,
          );

      setState(() {
        _semesters = semesters;
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching semesters: $e");
      setState(() {
        _isLoading = false;
      });
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
      setState(() {
        _courses = data;
      });
    } catch (e) {
      print("Error fetching courses: $e");
    }
  }

  Future<void> _pickFile() async {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a file type first')),
        );
        return;
      }

      if (!allowedExtensions[selectedType]!.contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid file type for $_selectedFileType')),
        );
        return;
      }

      setState(() => _selectedFile = file);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a file')));
      return;
    }

    if (_selectedCourseId == null ||
        _selectedFileType == null ||
        _selectedSemester == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final firebaseUser = FirebaseAuth.instance.currentUser;
    print(
      '🔹 Firebase user: ${firebaseUser?.uid} | email: ${firebaseUser?.email}',
    );

    if (firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firebase user not authenticated')),
      );
      return;
    }

    // To get selected course
    final selectedCourse = _courses.firstWhere(
      (course) => course['id'].toString() == _selectedCourseId!,
    );

    final courseCode = selectedCourse['course_code'] as String;

    // 🔹 All auth checks passed, proceed to upload
    try {
      setState(() {}); // optional: trigger loading indicator

      await ref
      .read(uploadMaterialControllerProvider.notifier)
      
      .uploadMaterial(
        uploaderId: firebaseUser.uid,
        department: widget.currentUser.department,
        courseId: _selectedCourseId!,
        fileType: _selectedFileType!,
        file: _selectedFile!,
        level: _parseLevel(widget.currentUser.level),
        semester: _selectedSemester!, 
        courseCode: courseCode,
      );

      // After successful upload
      context.go(RouteNames.thankYou);

      setState(() {
        _selectedFile = null;
        _selectedCourseId = null;
        _selectedFileType = null;
        _selectedSemester = null;
      });
    } catch (e) {
      print('❌ Upload failed: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(uploadMaterialControllerProvider);

    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Upload File'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(FluentSystemIcons.ic_fluent_ios_arrow_left_filled),
          color: AppStyles.subText,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildReadonlyField("Department", widget.currentUser.department),
              SizedBox(height: 16),
              _buildReadonlyField("Level", widget.currentUser.level),

              SizedBox(height: 16),

              // Semester Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSemester,
                isExpanded: true,
                items: _semesters
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSemester = value;
                    _selectedCourseId = null;
                    if (value != null) _loadCourses(value);
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Select Semester',
                  hintStyle: AppStyles.hintStyle,
                  filled: true,
                  fillColor: AppStyles.backgroundColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (v) => v == null ? 'Please select a semester' : null,
              ),

              SizedBox(height: 16),

              // Course Dropdown
              DropdownButtonFormField<String>(
                value: _selectedCourseId,
                isExpanded: true,
                items: _courses
                    .map(
                      (course) => DropdownMenuItem(
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
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (v) => v == null ? 'Please select a course' : null,
              ),
              SizedBox(height: 16),

              // File Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedFileType,
                isExpanded: true,
                items: _fileTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFileType = v),
                decoration: InputDecoration(
                  hintText: 'Select File Type',
                  hintStyle: AppStyles.hintStyle,
                  filled: true,
                  fillColor: AppStyles.backgroundColor,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (v) =>
                    v == null ? 'Please select a file type' : null,
              ),
              SizedBox(height: 16),

              // File Picker
              GestureDetector(
                onTap: _pickFile,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 48),
                  decoration: BoxDecoration(
                    color: AppStyles.backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          FluentSystemIcons.ic_fluent_folder_filled,
                          color: AppStyles.accentColor,
                          size: 35,
                        ),
                        SizedBox(width: 10),
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
              SizedBox(height: 24),

              // Submit as TextButton.icon (styled like edit button)
              TextButton.icon(
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(vertical: 12),
                  ),
                  backgroundColor: WidgetStateProperty.resolveWith(
                    (states) => AppStyles.primaryColor,
                  ),
                  foregroundColor: WidgetStateProperty.resolveWith(
                    (states) => AppStyles.accentColor,
                  ),
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                onPressed: () {
                  if (uploadState.isLoading) return;
                  _submit();
                },
                icon: uploadState.isLoading
                    ? SizedBox(
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
        SizedBox(height: 6),
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
}
