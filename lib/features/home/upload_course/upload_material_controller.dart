import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'upload_material_repository.dart';

final uploadMaterialControllerProvider =
    StateNotifierProvider<UploadMaterialController, AsyncValue<void>>(
  (ref) => UploadMaterialController(UploadMaterialRepository()),
);

class UploadMaterialController extends StateNotifier<AsyncValue<void>> {
  final UploadMaterialRepository _repo;
  UploadMaterialController(this._repo) : super(const AsyncData(null));

  /// Pick file from device
  Future<File?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      return File(result.files.single.path!);
    }
    return null;
  }

  /// Fetch semesters available
  Future<List<String>> fetchSemesters({
    required String department,
    required int level,
  }) =>
      _repo.fetchSemesters(department: department, level: level);

  /// Fetch courses
  Future<List<Map<String, dynamic>>> fetchCourses({
    required String department,
    required int level,
    required String semester,
  }) =>
      _repo.fetchCourses(department: department, level: level, semester: semester);

  /// Upload material file
  Future<void> uploadMaterial({
    required String uploaderId,
    required String department,
    required String courseId,
    required String courseCode,
    required String fileType,
    required File file,
    required int level,
    required String semester,
  }) async {
    state = const AsyncLoading();
    try {
      await _repo.uploadMaterial(
        uploaderId: uploaderId,
        department: department,
        courseId: courseId,
        courseCode: courseCode,
        fileType: fileType,
        file: file,
        level: level,
        semester: semester, 
      );
      state = const AsyncData(null);
    } catch (e, st) {
      print('❌ Upload failed: $e');
      state = AsyncError(e, st);
      rethrow;
    }
  }
}
