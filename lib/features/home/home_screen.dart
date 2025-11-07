import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/media.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/base/widgets/course/course_list.dart';
import 'package:peer_net/base/widgets/route_double_text.dart';
import 'package:peer_net/features/AUTH/application/auth_providers.dart';
import 'package:peer_net/features/COURSES/application/course_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user.value;
    final randomCoursesAsync = ref.watch(randomCoursesProvider);

    // Refresh random courses when user pulls down
    Future<void> refreshCourses() async {
      ref.invalidate(randomCoursesProvider);
    }

    final accentBg = AppStyles.accentColor.withValues(alpha: 0.1);

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: refreshCourses,
          color: AppStyles.primaryColor,
          backgroundColor: Colors.white,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ======= Top Bar =======
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Image.asset(AppMedia.logo, scale: 4.8),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      FluentSystemIcons.ic_fluent_upload_regular,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      if (user != null) {
                                        context.push(RouteNames.uploads, extra: user);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("User not loaded yet"),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      FluentSystemIcons.ic_fluent_alert_regular,
                                      size: 28,
                                    ),
                                    onPressed: () {
                                      context.push(RouteNames.notifications);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 15),

                        // ======= Greeting & Department Info =======
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
                                      style: AppStyles.header1.copyWith(color: primary),
                                    ),
                                    TextSpan(
                                      text: user?.nickname.trim().split(' ').last ?? 'User',
                                      style: AppStyles.header1.copyWith(color: accent),
                                    ),
                                    const TextSpan(text: ' 👋'),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: accentBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    style: Theme.of(context).textTheme.bodyLarge,
                                    children: [
                                      const TextSpan(
                                        text: 'Department: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: '${user?.department ?? 'Unknown'}\n'),
                                      const TextSpan(
                                        text: 'Level: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: user?.level ?? 'N/A'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ======= Bottom Section (fills remaining height) =======
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: accentBg,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 16,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // === Courses ===
                                  RouteDoubleText(
                                    bigText: 'My Courses',
                                    smallText: 'View All',
                                    func: () => context.go(RouteNames.courses),
                                  ),
                                  const SizedBox(height: 12),

                                  randomCoursesAsync.when(
                                    data: (courses) {
                                      if (courses.isEmpty) {
                                        return const Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Text('No courses available.'),
                                        );
                                      }
                                      return CourseList(
                                        courses: courses,
                                        onCourseTap: (course) {
                                          context.push(
                                            RouteNames.courseDetails,
                                            extra: course,
                                          );
                                        },
                                      );
                                    },
                                    loading: () => const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(24),
                                        child: CircularProgressIndicator(),
                                      ),
                                    ),
                                    error: (err, st) => Padding(
                                      padding: const EdgeInsets.all(20),
                                      child: Text('Error: $err'),
                                    ),
                                  ),

                                  const SizedBox(height: 28),

                                  // === Connect Section ===
                                  Text('Connect', style: AppStyles.doubleText1),
                                  const SizedBox(height: 12),
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
                                            Text(
                                              'User ${index + 1}',
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 40), // bottom spacing
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
