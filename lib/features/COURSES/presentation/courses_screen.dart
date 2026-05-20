import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/base/widgets/course/course_card.dart';
import 'package:peer_net/base/widgets/course/course_card_skeleton.dart';
import 'package:peer_net/features/COURSES/application/course_provider.dart';
import 'package:peer_net/base/widgets/network_error_widget.dart';

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
  late int selectedLevel;

  // ✅ The critical fix to prevent StatefulShellRoute initialization crashes
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    selectedLevel = widget.level;

    // ✅ Defer heavy UI and data fetching until after the first frame renders.
    // This allows the app to boot instantly without choking the emulator CPU.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _changeLevel(int newLevel) {
    if (selectedLevel == newLevel) return; // Prevent unnecessary rebuilds
    setState(() {
      selectedLevel = newLevel;
      _tabController.index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======= Header =======
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Courses",
                    style: AppStyles.pageTitle.copyWith(fontSize: 32),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppStyles.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.department,
                      style: AppStyles.formLabelStyle.copyWith(
                        color: AppStyles.primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ======= Level Selector =======
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [100, 200, 300, 400, 500].map((lvl) {
                  final isSelected = selectedLevel == lvl;
                  return GestureDetector(
                    onTap: () => _changeLevel(lvl),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppStyles.primaryColor
                            : AppStyles.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected
                              ? AppStyles.primaryColor
                              : AppStyles.inputBorder,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppStyles.primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          "$lvl Lvl",
                          style: TextStyle(
                            color: isSelected
                                ? AppStyles.white
                                : AppStyles.headingColor,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // ======= Semester Tabs =======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: AppStyles.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppStyles.inputBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelColor: AppStyles.white,
                  unselectedLabelColor: AppStyles.labelText,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent, // remove bottom border
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: AppStyles.accentColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppStyles.accentColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  tabs: const [
                    Tab(text: "First Semester"),
                    Tab(text: "Second Semester"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ======= Tab Contents =======
            Expanded(
              child: !_isReady
                  ? const _CourseGridSkeleton()
                  : TabBarView(
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
    // This will only trigger AFTER _isReady becomes true in the parent widget
    final asyncCourses = ref.watch(
      coursesProvider(CourseParams(department, level, semester)),
    );

    if (asyncCourses.isLoading) {
      return const _CourseGridSkeleton();
    }

    return asyncCourses.when(
      data: (courses) {
        if (courses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_off_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                const Text("No courses found for this semester."),
              ],
            ),
          );
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.85,
          ),
          itemCount: courses.length,
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
          itemBuilder: (context, index) {
            final course = courses[index];

            return CourseCard(
              onTap: () {
                context.pushNamed(RouteNames.courseDetails, extra: course);
              },
              courseCode: course.courseCode,
              courseName: course.courseName,
            );
          },
        );
      },
      loading: () => const _CourseGridSkeleton(),
      error: (e, st) => NetworkErrorWidget(
        message: e.toString().replaceAll('Exception: ', ''),
        onRetry: () => ref.invalidate(
          coursesProvider(CourseParams(department, level, semester)),
        ),
      ),
    );
  }
}

class _CourseGridSkeleton extends StatelessWidget {
  const _CourseGridSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.85,
      ),
      itemCount: 6,
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
      itemBuilder: (context, index) => const CourseCardSkeleton(),
    );
  }
}
