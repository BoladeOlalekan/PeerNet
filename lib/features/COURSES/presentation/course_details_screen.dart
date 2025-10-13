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
      appBar: AppBar(
        title: Text(
          "${course.courseCode} - ${course.courseName}",
          style: AppStyles.doubleText1.copyWith(fontWeight: FontWeight.w500),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: AppStyles.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
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
                          color: isSelected ? AppStyles.primaryColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tabs[index],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppStyles.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 30),

            // Animated content switcher
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
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
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading resources: ${snapshot.error}",
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          );
        }

        final allResources = snapshot.data ?? [];
        final filtered = allResources
          .where((r) => r['file_type'] == tabType)
          .toList();

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              "No ${tabType.replaceAll('_', ' ')}s available yet.",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.only(top: 10, left: 8, right: 8, bottom: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 0.78,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, idx) {
            final resource = filtered[idx];
            return ResourceCard(
              fileName: resource['file_name'] ?? 'Untitled',
              fileType: resource['file_type'] ?? 'note',
              downloadUrl: resource['download_url'] ?? '',
            );
          },
        );
      },
    );
  }
}