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
