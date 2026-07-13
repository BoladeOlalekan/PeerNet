import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/widgets/course/resource_card.dart';
import 'package:peer_net/features/COURSES/application/course_controller.dart';
import 'package:peer_net/features/COURSES/models/course_model.dart';

class CourseDetailsScreen extends StatefulWidget {
  final CourseModel course;
  const CourseDetailsScreen({super.key, required this.course});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  int selectedIndex = 0;
  final List<String> tabs = ["Notes", "Videos", "Past Questions"];

  @override
  Widget build(BuildContext context) {
    final course = widget.course;

    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======= Header with Back Button =======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppStyles.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppStyles.inputBorder),
                      ),
                      child: const Icon(
                        FluentSystemIcons.ic_fluent_ios_arrow_left_filled,
                        size: 20,
                        color: AppStyles.headingColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Course Details",
                    style: AppStyles.pageTitle.copyWith(fontSize: 22),
                  ),
                ],
              ),
            ),

            // ======= Course Overview Card =======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppStyles.primaryColor,
                      AppStyles.primaryColor.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppStyles.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        course.courseCode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      course.courseName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      children: [
                        _OverviewStat(
                          icon: FluentSystemIcons.ic_fluent_building_regular,
                          label: course.department,
                        ),
                        _OverviewStat(
                          icon: FluentSystemIcons
                              .ic_fluent_classification_regular,
                          label: "${course.level} Level",
                        ),
                        _OverviewStat(
                          icon: FluentSystemIcons
                              .ic_fluent_calendar_3_day_regular,
                          label: "${course.semester} Semester",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ======= Sleek Segmented Tab Bar =======
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppStyles.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppStyles.inputBorder),
                ),
                child: Row(
                  children: List.generate(tabs.length, (index) {
                    final isSelected = selectedIndex == index;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedIndex = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCirc,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppStyles.primaryColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(26),
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
                          alignment: Alignment.center,
                          child: Text(
                            tabs[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppStyles.labelText,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ======= Content Grid =======
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 100),
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.1, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: _buildTabContent(course, selectedIndex),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(CourseModel course, int index) {
    final tabType = switch (index) {
      0 => 'note',
      1 => 'video',
      2 => 'past_question',
      _ => 'note',
    };

    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(tabType),
      future: fetchCourseResources(course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.78,
            ),
            itemCount: 4,
            itemBuilder: (context, idx) => const ResourceCardSkeleton(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  "Error loading resources",
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        final allResources = snapshot.data ?? [];
        final filtered = allResources
            .where((r) => r['file_type'] == tabType)
            .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  FluentSystemIcons.ic_fluent_folder_open_regular,
                  size: 64,
                  color: AppStyles.inputBorder,
                ),
                const SizedBox(height: 16),
                Text(
                  "No ${tabType.replaceAll('_', ' ')}s available yet.",
                  style: const TextStyle(
                    color: AppStyles.mutedText,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, idx) {
            final resource = filtered[idx];
            return ResourceCard(
              fileName:
                  resource['file_name'] ?? resource['fileName'] ?? 'Untitled',
              fileType: resource['file_type'] ?? 'note',
              downloadUrl: resource['download_url'] ?? '',
              youtubeUrl: resource['youtube_url'] ?? '',
            );
          },
        );
      },
    );
  }
}

class _OverviewStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OverviewStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
