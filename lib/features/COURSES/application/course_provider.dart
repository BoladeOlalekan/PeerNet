import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/features/AUTH/application/auth_providers.dart';
import 'package:peer_net/features/COURSES/application/course_controller.dart';
import 'package:peer_net/features/COURSES/models/course_model.dart';

final randomCoursesProvider = FutureProvider.autoDispose<List<CourseModel>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.user.value;
  if (user == null) return [];
  // Extract numeric part from level string, e.g., "500 Level" -> 500
  final levelNumber = int.tryParse(user.level.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  return fetchRandomCourses(
    department: user.department,
    level: levelNumber,
    count: 4,
  );
});
