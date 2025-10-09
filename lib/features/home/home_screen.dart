import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/base/media.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/widgets/course/course_list.dart';
import 'package:peer_net/base/widgets/route_double_text.dart';
import 'package:peer_net/features/AUTH/application/auth_providers.dart';
import 'package:peer_net/features/COURSES/application/course_provider.dart';
import 'package:peer_net/features/COURSES/presentation/course_details_screen.dart';
//import 'package:peer_net/features/AUTH/data/auth_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user.value;
    final randomCoursesAsync = ref.watch(randomCoursesProvider);
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Image.asset(AppMedia.logo, scale: 4.8),

                  Row(
                    children: [
                      IconButton(
                        icon: Icon(FluentSystemIcons.ic_fluent_upload_regular, size: 30),
                        onPressed: () {}, 
                      ),
                      IconButton(
                        icon: const Icon(FluentSystemIcons.ic_fluent_alert_regular, size: 30),
                        onPressed: () {}, 
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 15),

            // Department & Level as well as greeting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppStyles.header1,
                      children: [
                        TextSpan(
                          text: 'Hello, ',
                          style: AppStyles.header1.copyWith(color: primary)
                        ),
                        TextSpan(
                          text: user?.name.trim().split(' ').last ?? 'User',
                          style: AppStyles.header1.copyWith(color: accent),
                        ),
                        const TextSpan(text: '👋'),
                      ],
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppStyles.accentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyLarge,
                        children: [
                          TextSpan(
                            text: 'Department: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '${user?.department ?? 'Unknown'}\n',
                          ),
                          TextSpan(
                            text: 'Level: ',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: user?.level ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Next Section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppStyles.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // COURSES SECTION
                      RouteDoubleText(
                        bigText: 'My Courses',
                        smallText: 'View All',
                        func: () {},
                      ),

                      const SizedBox(height: 12),

                      randomCoursesAsync.when(
                        data: (courses) {
                          print('Fetched courses: ${courses.map((c) => c.courseName).toList()}');
                          return CourseList(
                            courses: courses,
                            onCourseTap: (course) {
                              CourseDetailsScreen(course: course);
                              print('Tapped on course: ${course.courseName} (${course.courseCode})');
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, st) => Text('Error: $err'),
                      ),

                      SizedBox(height: 20),

                      // Connect Section
                      Text(
                        'Connect', 
                        style: AppStyles.doubleText1
                      ),

                      SizedBox(height: 12),
                      
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 8,
                          itemBuilder: (context, index) => Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage: NetworkImage(
                                    'https://i.pravatar.cc/150?img=${index + 1}',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text('User ${index + 1}', style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
