import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadMaterialRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<String>> fetchSemesters({
    required String department,
    required int level,
  }) async {
    final data = await _supabase
        .from('courses')
        .select('semester')
        .eq('department', department)
        .eq('level', level);

    return data
        .map<String>((row) => row['semester'] as String)
        .toSet()
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchCourses({
    required String department,
    required int level,
    required String semester,
  }) async {
    final data = await _supabase
        .from('courses')
        .select()
        .eq('department', department)
        .eq('level', level)
        .eq('semester', semester);

    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> uploadMaterial({
    required String uploaderId,
    required String department,
    required String courseCode,
    required String courseId,
    required String fileType,
    required File file,
    required int level,
    required String semester,
  }) async {
    final fileName = p.basename(file.path);

    // Preserve your real folder casing and names
    final cleanDepartment = department.trim();
    final cleanLevel = level.toString();
    final cleanSemester = semester.trim();
    final cleanCourseCode = courseCode.trim().toUpperCase();
    //final cleanFileType = fileType.trim().toLowerCase().replaceAll(' ', '_');

    // 🔹 Map the UI fileType to Supabase database enum
    String mapFileTypeForDB(String type) {
      switch (type.toLowerCase()) {
        case 'note':
          return 'note';
        case 'video':
          return 'video';
        case 'past question':
          return 'past_question';
        default:
          return 'note';
      }
    }

    // Map UI fileType to storage folder
    String mapFileTypeForStorage(String type) {
      switch (type.toLowerCase()) {
        case 'note':
          return 'notes';
        case 'video':
          return 'videos';
        case 'past question':
          return 'past_questions';
        default:
          return 'others';
      }
    }

    final dbFileType = mapFileTypeForDB(fileType);
    final storageFileType = mapFileTypeForStorage(fileType);
    final timestampedFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';

    final storagePath = 'resources/$cleanDepartment/$cleanLevel/$cleanSemester/$cleanCourseCode/$storageFileType/$timestampedFileName';

    final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

    print('📤 Uploading file: $fileName → $storagePath');

    final fileBytes = await file.readAsBytes();
    await _supabase.storage
    .from('resources')
    .uploadBinary(
      storagePath,
      fileBytes,
      fileOptions: const FileOptions(upsert: false),
    );

    await _supabase.from('resources').insert({
      'course_id': courseId,
      'uploader_firebase_uid': uploaderId,
      'storage_path': storagePath,
      'mime_type': mimeType,
      'size_bytes': await file.length(),
      'file_type': dbFileType,
      'approval_status': 'pending',
      'file_name': fileName,
      'created_at': DateTime.now().toIso8601String(),
    });

    print('✅ Upload metadata inserted successfully.');
  }
}
