import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/base/widgets/course/course_card_skeleton.dart';
import 'package:shimmer/shimmer.dart';
import 'package:peer_net/base/widgets/course/course_list.dart';
//import 'package:peer_net/base/widgets/route_double_text.dart';
import 'package:peer_net/features/auth/application/auth_providers.dart';
import 'package:peer_net/features/COURSES/application/course_provider.dart';
import 'package:peer_net/base/widgets/network_error_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user.value;
    final isLoadingUser = user == null;
    final randomCoursesAsync = ref.watch(randomCoursesProvider);

    // Refresh random courses when user pulls down
    Future<void> refreshCourses() async {
      ref.invalidate(randomCoursesProvider);
    }

    String getGreeting() {
      final hour = DateTime.now().hour;
      if (hour < 17) {
        return 'Good day,';
      } else {
        return 'Good evening,';
      }
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: AppStyles.backgroundColor,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: refreshCourses,
          color: AppStyles.primaryColor,
          backgroundColor: AppStyles.white,
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
                        const SizedBox(height: 10),

                        // ======= Header Section =======
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getGreeting(),
                                    style: AppStyles.pageSubtitle,
                                  ),
                                  const SizedBox(height: 4),
                                  isLoadingUser
                                      ? Shimmer.fromColors(
                                          baseColor: Colors.grey.shade300,
                                          highlightColor: Colors.grey.shade100,
                                          child: Container(
                                            height: 32,
                                            width: 120,
                                            decoration: BoxDecoration(
                                              color: AppStyles.white,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        )
                                      : Text(
                                          user.nickname.trim().split(' ').last,
                                          style: AppStyles.pageTitle.copyWith(
                                            fontSize: 28,
                                          ),
                                        ),
                                ],
                              ),
                              Row(
                                children: [
                                  _buildIconButton(
                                    icon: FluentSystemIcons
                                        .ic_fluent_upload_regular,
                                    onPressed: () {
                                      if (user != null) {
                                        context.push(
                                          RouteNames.uploads,
                                          extra: user,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "User not loaded yet",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 12),
                                  _buildIconButton(
                                    icon: FluentSystemIcons
                                        .ic_fluent_alert_regular,
                                    onPressed: () =>
                                        context.push(RouteNames.notifications),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ======= Department Card =======
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppStyles.primaryColor,
                                  AppStyles.primaryColor.withValues(
                                    alpha: 0.85,
                                  ),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppStyles.primaryColor.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppStyles.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      width: 2,
                                    ),
                                  ),
                                  child: isLoadingUser
                                      ? Shimmer.fromColors(
                                          baseColor: AppStyles.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          highlightColor: AppStyles.white
                                              .withValues(alpha: 0.5),
                                          child: const CircleAvatar(
                                            radius: 32,
                                            backgroundColor: AppStyles.white,
                                          ),
                                        )
                                      : CircleAvatar(
                                          radius: 32,
                                          backgroundColor:
                                              AppStyles.transparent,
                                          backgroundImage:
                                              (user.avatarUrl ?? '').isNotEmpty
                                              ? CachedNetworkImageProvider(
                                                  user.avatarUrl!,
                                                )
                                              : const NetworkImage(
                                                      'https://lh3.googleusercontent.com/aida-public/AB6AXuAtUmPCV6_iCOw7mfIDLIbHfyRdhGLNhWrGUWwKzn10lTqztThDu-icL7IiAM75CLZHodix_8vcv77mkcS22DlZWH3GF6agpNnWFM56lErAWXkkILztdTCEadhGWfSyRkAgXp33mRtDq_uYzSceLJmsJ3TLKmiIBQzsfUQ-F9bI4u5iIkhyMDqiQ8_PQL8-B_pBDgmUKDDusHVyuvibsO9n39azqEzIskQ-uQ7T_N_gAEI9eacxj6NEdq_P0AVrkN-GoZpx7C7CZmQ',
                                                    )
                                                    as ImageProvider,
                                        ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Department:',
                                        style: TextStyle(
                                          color: AppStyles.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      isLoadingUser
                                          ? Shimmer.fromColors(
                                              baseColor: AppStyles.white
                                                  .withValues(alpha: 0.2),
                                              highlightColor: AppStyles.white
                                                  .withValues(alpha: 0.5),
                                              child: Container(
                                                height: 20,
                                                width: 140,
                                                decoration: BoxDecoration(
                                                  color: AppStyles.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              user.department,
                                              style: const TextStyle(
                                                color: AppStyles.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Level:',
                                        style: TextStyle(
                                          color: AppStyles.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      isLoadingUser
                                          ? Shimmer.fromColors(
                                              baseColor: AppStyles.white
                                                  .withValues(alpha: 0.2),
                                              highlightColor: AppStyles.white
                                                  .withValues(alpha: 0.5),
                                              child: Container(
                                                height: 20,
                                                width: 80,
                                                decoration: BoxDecoration(
                                                  color: AppStyles.white,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              user.level.toString(),
                                              style: const TextStyle(
                                                color: AppStyles.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ======= Bottom Section =======
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: AppStyles.white,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(32),
                                topRight: Radius.circular(32),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // === Courses ===
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'My Courses',
                                        style: AppStyles.pageTitle.copyWith(
                                          fontSize: 22,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            context.go(RouteNames.courses),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              AppStyles.accentColor,
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'View All',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),

                                  (isLoadingUser ||
                                          randomCoursesAsync.isLoading)
                                      ? SizedBox(
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.25,
                                          child: ListView.builder(
                                            scrollDirection: Axis.horizontal,
                                            itemCount: 3,
                                            itemBuilder: (context, index) =>
                                                const CourseCardSkeleton(
                                                  width: 160,
                                                  margin: EdgeInsets.only(
                                                    right: 16,
                                                    bottom: 8,
                                                    top: 4,
                                                  ),
                                                ),
                                          ),
                                        )
                                      : randomCoursesAsync.when(
                                          data: (courses) {
                                            if (courses.isEmpty) {
                                              return Container(
                                                padding: const EdgeInsets.all(
                                                  24,
                                                ),
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color: AppStyles.inputFill,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color:
                                                        AppStyles.inputBorder,
                                                  ),
                                                ),
                                                child: const Text(
                                                  'No courses available right now.',
                                                  style: TextStyle(
                                                    color: AppStyles.mutedText,
                                                    fontSize: 15,
                                                  ),
                                                ),
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
                                          loading: () => SizedBox(
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.25,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: 3,
                                              itemBuilder: (context, index) =>
                                                  const CourseCardSkeleton(
                                                    width: 160,
                                                    margin: EdgeInsets.only(
                                                      right: 16,
                                                      bottom: 8,
                                                      top: 4,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          error: (err, st) => SizedBox(
                                            height:
                                                MediaQuery.of(
                                                  context,
                                                ).size.height *
                                                0.25,
                                            child: NetworkErrorWidget(
                                              isCompact: true,
                                              message: err
                                                  .toString()
                                                  .replaceAll(
                                                    'Exception: ',
                                                    '',
                                                  ),
                                              onRetry: () => ref.invalidate(
                                                randomCoursesProvider,
                                              ),
                                            ),
                                          ),
                                        ),

                                  const SizedBox(height: 36),

                                  // === Connect Section ===
                                  Text(
                                    'Connect with Peers',
                                    style: AppStyles.pageTitle.copyWith(
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 8,
                                      clipBehavior: Clip.none,
                                      itemBuilder: (context, index) {
                                        if (isLoadingUser) {
                                          return Container(
                                            width: 72,
                                            margin: const EdgeInsets.only(
                                              right: 16,
                                            ),
                                            child: Column(
                                              children: [
                                                Shimmer.fromColors(
                                                  baseColor:
                                                      Colors.grey.shade300,
                                                  highlightColor:
                                                      Colors.grey.shade100,
                                                  child: Container(
                                                    width: 64,
                                                    height: 64,
                                                    decoration:
                                                        const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color:
                                                              AppStyles.white,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Shimmer.fromColors(
                                                  baseColor:
                                                      Colors.grey.shade300,
                                                  highlightColor:
                                                      Colors.grey.shade100,
                                                  child: Container(
                                                    height: 12,
                                                    width: 48,
                                                    decoration: BoxDecoration(
                                                      color: AppStyles.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        return Container(
                                          width: 72,
                                          margin: const EdgeInsets.only(
                                            right: 16,
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AppStyles
                                                        .primaryColor
                                                        .withValues(alpha: 0.1),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: CircleAvatar(
                                                  radius: 30,
                                                  backgroundColor:
                                                      AppStyles.inputFill,
                                                  backgroundImage: NetworkImage(
                                                    'https://i.pravatar.cc/150?img=${index + 10}',
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'User ${index + 1}',
                                                style: AppStyles.formLabelStyle
                                                    .copyWith(
                                                      fontSize: 12,
                                                      color: AppStyles
                                                          .headingColor,
                                                    ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        );
                                      },
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

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppStyles.inputBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppStyles.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 22, color: AppStyles.headingColor),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
