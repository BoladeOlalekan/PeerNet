import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:shimmer/shimmer.dart';

final allCoursesMapProvider = FutureProvider<Map<String, String>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('courses').select('id, course_code');
  final map = <String, String>{};
  for (final row in response) {
    final id = row['id'].toString();
    final code = row['course_code'] as String? ?? 'Unknown';
    map[id] = code;
  }
  return map;
});

final userUploadsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final supabase = Supabase.instance.client;

  if (userId == null) return const Stream.empty();

  return supabase
      .from('resources')
      .stream(primaryKey: ['id'])
      .eq('uploader_firebase_uid', userId)
      .order('created_at', ascending: false)
      .map((rows) => rows);
});

class UserUploadsScreen extends ConsumerStatefulWidget {
  const UserUploadsScreen({super.key});

  @override
  ConsumerState<UserUploadsScreen> createState() => _UserUploadsScreenState();
}

class _UserUploadsScreenState extends ConsumerState<UserUploadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatSize(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Unknown size';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          if (difference.inMinutes == 0) {
            return 'Just now';
          }
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        final months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];
        return '${months[date.month - 1]} ${date.day}, ${date.year}';
      }
    } catch (_) {
      return 'Unknown date';
    }
  }

  IconData _getIconForFile(String? fileType) {
    switch (fileType?.toLowerCase()) {
      case 'note':
        return FluentSystemIcons.ic_fluent_document_regular;
      case 'video':
        return FluentSystemIcons.ic_fluent_video_clip_regular;
      case 'past_question':
      case 'past question':
        return FluentSystemIcons.ic_fluent_history_filled;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return const Color(0xFFC62828);
      case 'pending':
      default:
        return const Color(0xFFEF6C00);
    }
  }

  Color _statusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFFE8F5E9);
      case 'rejected':
        return const Color(0xFFFFEBEE);
      case 'pending':
      default:
        return const Color(0xFFFFF3E0);
    }
  }

  Widget _buildEmptyState(String filterName) {
    IconData icon;
    String message;
    switch (filterName) {
      case 'Pending':
        icon = FluentSystemIcons.ic_fluent_clock_regular;
        message = 'No pending uploads';
        break;
      case 'Approved':
        icon = FluentSystemIcons.ic_fluent_checkmark_circle_regular;
        message = 'No approved uploads';
        break;
      case 'Rejected':
        icon = FluentSystemIcons.ic_fluent_dismiss_circle_regular;
        message = 'No rejected uploads';
        break;
      default:
        icon = Icons.cloud_upload_outlined;
        message = 'No uploads found';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppStyles.accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppStyles.accentColor),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                color: AppStyles.headingColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? "We couldn't find any uploads matching \"$_searchQuery\"."
                  : 'Your uploaded materials will appear here with their review status.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppStyles.mutedText,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonItem() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppStyles.inputBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 80,
            height: 26,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: 5,
        itemBuilder: (context, index) => _buildSkeletonItem(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppStyles.backgroundColor,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'My Uploads',
        style: AppStyles.pageTitle.copyWith(fontSize: 20),
      ),
      leading: IconButton(
        icon: const Icon(FluentSystemIcons.ic_fluent_ios_arrow_left_filled),
        color: AppStyles.headingColor,
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildTabSelector() {
    final tabs = ['All', 'Pending', 'Approved', 'Rejected'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppStyles.inputBorder),
        ),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: AppStyles.labelText,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppStyles.primaryColor,
            boxShadow: [
              BoxShadow(
                color: AppStyles.primaryColor.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          tabs: [for (final t in tabs) Tab(text: t)],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: AppStyles.inputTextStyle,
        decoration:
            AppStyles.inputDecoration(
              hint: 'Search by filename or course...',
            ).copyWith(
              prefixIcon: const Icon(
                FluentSystemIcons.ic_fluent_search_regular,
                color: AppStyles.iconMuted,
                size: 20,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: AppStyles.iconMuted,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uploadsAsync = ref.watch(userUploadsProvider);
    final coursesAsync = ref.watch(allCoursesMapProvider);

    final tabs = ['All', 'Pending', 'Approved', 'Rejected'];

    if ((uploadsAsync.isLoading && !uploadsAsync.hasValue) ||
        (coursesAsync.isLoading && !coursesAsync.hasValue)) {
      return Scaffold(
        backgroundColor: AppStyles.backgroundColor,
        appBar: _buildAppBar(),
        body: Column(
          children: [
            _buildTabSelector(),
            _buildSearchBar(),
            Expanded(child: _buildSkeletonList()),
          ],
        ),
      );
    }

    if (uploadsAsync.hasError) {
      return Scaffold(
        backgroundColor: AppStyles.backgroundColor,
        appBar: _buildAppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Error loading uploads: ${uploadsAsync.error}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final uploads = uploadsAsync.value ?? [];
    final coursesMap = coursesAsync.value ?? {};

    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabSelector(),
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabs.map((category) {
                final filtered = uploads.where((item) {
                  final status = item['approval_status'] ?? 'pending';

                  // Filter by status tab
                  bool statusMatches = false;
                  switch (category) {
                    case 'All':
                      statusMatches = true;
                      break;
                    case 'Pending':
                      statusMatches =
                          status.toString().toLowerCase() == 'pending';
                      break;
                    case 'Approved':
                      statusMatches =
                          status.toString().toLowerCase() == 'approved';
                      break;
                    case 'Rejected':
                      statusMatches =
                          status.toString().toLowerCase() == 'rejected';
                      break;
                  }

                  if (!statusMatches) return false;

                  // Filter by search query (filename or course code)
                  if (_searchQuery.isNotEmpty) {
                    final filename = (item['file_name'] as String? ?? '')
                        .toLowerCase();
                    final courseId = (item['course_id'] as String? ?? '')
                        .toLowerCase();

                    // Look up course code
                    final courseCode =
                        (coursesMap[item['course_id']?.toString()] ?? '')
                            .toLowerCase();

                    final matchesQuery =
                        filename.contains(_searchQuery.toLowerCase()) ||
                        courseCode.contains(_searchQuery.toLowerCase()) ||
                        courseId.contains(_searchQuery.toLowerCase());
                    return matchesQuery;
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(category);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final upload = filtered[index];
                    final status = upload['approval_status'] ?? 'pending';
                    final fileType = upload['file_type'] as String? ?? 'note';
                    final fileName =
                        upload['file_name'] as String? ?? 'Untitled';
                    final sizeText = _formatSize(upload['size_bytes'] as int?);
                    final timeText = _formatDate(
                      upload['created_at'] as String?,
                    );

                    // Look up course code using map
                    final courseIdStr = upload['course_id']?.toString();
                    final courseCode =
                        coursesMap[courseIdStr] ?? 'Unknown Course';

                    final icon = _getIconForFile(fileType);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppStyles.inputBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.015),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Material(
                          color: Colors.transparent,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppStyles.accentColor.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                icon,
                                color: AppStyles.accentColor,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              fileName,
                              style: const TextStyle(
                                color: AppStyles.headingColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                "$courseCode • $sizeText • $timeText",
                                style: const TextStyle(
                                  color: AppStyles.mutedText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _statusBgColor(status),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _statusColor(
                                    status,
                                  ).withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
