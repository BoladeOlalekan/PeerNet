import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/features/AUTH/application/auth_providers.dart';
import 'package:peer_net/features/COURSES/application/course_controller.dart';
import 'package:peer_net/features/COURSES/models/course_model.dart';

/// Value object for provider params
class CourseParams {
  final String department;
  final int level;
  final String semester;

  const CourseParams(this.department, this.level, this.semester);

  @override
  bool operator ==(Object other) =>
  identical(this, other) ||
  other is CourseParams &&
  runtimeType == other.runtimeType &&
  department == other.department &&
  level == other.level &&
  semester == other.semester;

  @override
  int get hashCode => department.hashCode ^ level.hashCode ^ semester.hashCode;
}

/// Fetch all courses for department + level + semester
final coursesProvider = FutureProvider.family<List<CourseModel>, CourseParams>((ref, params) async {
  return await fetchCourses(
    department: params.department,
    level: params.level,
    semester: params.semester,
  );
});

/// Fetch random courses for homepage
final randomCoursesProvider = FutureProvider.autoDispose<List<CourseModel>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.user.value;
  if (user == null) return [];

  final levelNumber = int.tryParse(user.level.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  return fetchRandomCourses(
    department: user.department,
    level: levelNumber,
    count: 4,
  );
});
