import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/features/COURSES/application/course_provider.dart';
import 'package:peer_net/features/COURSES/models/course_model.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  final String department;
  final int level;

  const CoursesScreen({
    super.key,
    required this.department,
    required this.level,
  });

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen>
  with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int selectedLevel = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    selectedLevel = widget.level;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeLevel(int newLevel) {
    setState(() {
      selectedLevel = newLevel;
      _tabController.index = 0; // ✅ reset to "First Semester"
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 10,
          top: 50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Courses",
              style: AppStyles.header1.copyWith(color: primary),
            ),

            // Semester Tabs
            TabBar(
              controller: _tabController,
              labelColor: primary,
              unselectedLabelColor: Colors.black54,
              indicatorColor: primary,
              tabs: const [
                Tab(text: "First Semester"),
                Tab(text: "Second Semester"),
              ],
            ),

            const SizedBox(height: 10),

            // Level + Department Label
            Text(
              "$selectedLevel Level - ${widget.department}",
              style: AppStyles.doubleText1,
            ),

            //const SizedBox(height: 5),

            // Tab Contents
            Expanded(
              flex: 8,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CourseListBuilder(
                    department: widget.department,
                    level: selectedLevel,
                    semester: "First",
                  ),
                  _CourseListBuilder(
                    department: widget.department,
                    level: selectedLevel,
                    semester: "Second",
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Other Levels Section
            Text(
              "Other Levels",
              style: AppStyles.doubleText1,
            ),

            SizedBox(
              height: size.height * 0.1,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [100, 200, 300, 400, 500].map((lvl) {
                  final isSelected = selectedLevel == lvl;
                  return GestureDetector(
                    onTap: () => _changeLevel(lvl),
                    child: Card(
                      margin: const EdgeInsets.only(right: 8),
                      color: isSelected
                          ? const Color(0xFF1E3A8A)
                          : const Color(0xFF10B981).withValues(alpha: 0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Text(
                            "$lvl Level",
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Builds a course list for one semester
class _CourseListBuilder extends ConsumerWidget {
  final String department;
  final int level;
  final String semester;

  const _CourseListBuilder({
    required this.department,
    required this.level,
    required this.semester,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCourses =
        ref.watch(coursesProvider(CourseParams(department, level, semester)));

    return asyncCourses.when(
      data: (courses) {
        if (courses.isEmpty) {
          return const Center(
              child: Text("No courses found for this level/semester."));
        }
        return ListView.builder(
          itemCount: courses.length,
          itemBuilder: (context, index) {
            final course = courses[index];
            return ListTile(
              title: Text("${course.courseCode} - ${course.courseName}"),
              subtitle: Text("$semester Semester"),
              onTap: () {
                // Example navigation to details screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailsScreen(course: course),
                  ),
                );
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text("Error: $e")),
    );
  }
}

// Example details screen
class CourseDetailsScreen extends StatelessWidget {
  final CourseModel course;
  const CourseDetailsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${course.courseCode} - ${course.courseName}"),
      ),
      body: const Center(child: Text("Notes | Videos | Past Questions here")),
    );
  }
}
