import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/widgets/course/course_card.dart';
import 'package:peer_net/features/COURSES/application/course_provider.dart';
import 'package:peer_net/features/COURSES/presentation/course_details_screen.dart';

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
      _tabController.index = 0;
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

            SizedBox(height: 10),

            // Level + Department Label
            Text(
              "$selectedLevel Level - ${widget.department}",
              style: AppStyles.doubleText1,
            ),

            SizedBox(height: 5),

            // Tab Contents
            Expanded(
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

            const SizedBox(height: 20),

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
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, 
                        vertical: 10
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                          ? AppStyles.primaryColor.withValues(alpha: .9)
                          : AppStyles.accentColor.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black87.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "$lvl Level",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
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
    final asyncCourses = ref.watch(coursesProvider(CourseParams(department, level, semester)));

    return asyncCourses.when(
      data: (courses) {
        if (courses.isEmpty) {
          return const Center(
            child: Text("No courses found for this level/semester.")
          );
        }
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 15.0,
            childAspectRatio: 0.9,
          ),
          itemCount: courses.length,
          padding: EdgeInsets.all(10.0),

          itemBuilder: (context, index) {
            final course = courses[index];

            return CourseCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseDetailsScreen(course: course),
                  ),
                );
              }, 
              courseCode: course.courseCode, 
              courseName: course.courseName,
            );
          },
        );

      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text("Error: $e")),
    );
  }
}
