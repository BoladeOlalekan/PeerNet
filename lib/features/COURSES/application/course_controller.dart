import 'package:peer_net/features/COURSES/models/course_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<List<CourseModel>> fetchCourses({
  required String department,
  required int level,
  required String semester,
}) async {
  try {
    print("DEBUG: fetching courses dept=$department, level=$level, semester=$semester");

    final response = await Supabase.instance.client
        .from('courses')
        .select()
        .ilike('department', department)
        .eq('level', level)
        .eq('semester', semester);

    print("DEBUG: Supabase response = $response");

    final data = response as List;
    return data.map((json) => CourseModel.fromJson(json)).toList();
  } catch (e, st) {
    print("ERROR: $e\n$st");
    throw Exception('Failed to fetch courses: $e');
  }
}

Future<List<CourseModel>> fetchRandomCourses({
  required String department,
  required int level,
  int count = 4,
}) async {
  try {
    final response = await Supabase.instance.client.rpc(
      'random_courses',
      params: {
        'p_department': department,
        'p_level': level,
        'p_count': count,
      },
    );

    if (response == null) return [];
    final data = response as List<dynamic>;
    return data.map((json) => CourseModel.fromJson(json as Map<String, dynamic>)).toList();
  } catch (e) {
    throw Exception('Failed to fetch random courses: $e');
  }
}

Future<List<Map<String, dynamic>>> fetchCourseResources(String courseId) async {
  try {
    print("DEBUG: fetching resources for courseId=$courseId");

    final response = await Supabase.instance.client
        .from('resources')
        .select('id, storage_path, file_type, created_at, approval_status')
        .eq('course_id', courseId)
        .eq('approval_status', 'approved')
        .order('created_at', ascending: false);

    final data = response as List<dynamic>;
    print("DEBUG: fetched ${data.length} resources");

    return data.map((item) {
      final map = Map<String, dynamic>.from(item as Map<String, dynamic>);
      final path = map['storage_path'] as String?;
      final fileType = map['file_type'] as String? ?? 'note';

      final fileName = path?.split('/').last ?? 'Untitled';
      final downloadUrl = path != null
          ? Supabase.instance.client.storage.from('resources').getPublicUrl(path)
          : '';

      return {
        ...map,
        'file_name': fileName,
        'file_type': fileType,
        'download_url': downloadUrl,
      };
    }).toList();
  } catch (e, st) {
    print("ERROR fetching course resources: $e\n$st");
    throw Exception('Failed to fetch resources: $e');
  }
}
