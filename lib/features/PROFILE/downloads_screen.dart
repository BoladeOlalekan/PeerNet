import 'package:flutter/material.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:peer_net/services/download_service.dart' as ds;
import 'package:share_plus/share_plus.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  List<ds.DownloadedResource> _downloads = [];
  String _searchQuery = '';

  String get _currentSearchHint {
    switch (_tabController.index) {
      case 0:
        return 'Search notes';
      case 1:
        return 'Search videos';
      case 2:
        return 'Search past questions';
      default:
        return 'Search downloads';
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    final all = await ds.DownloadService.getAllDownloads();
    setState(() => _downloads = all);
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

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
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
  }

  IconData _getIconForFile(String fileType) {
    switch (fileType) {
      case 'note':
        return FluentSystemIcons.ic_fluent_document_regular;
      case 'video':
        return FluentSystemIcons.ic_fluent_video_clip_regular;
      case 'past_question':
        return FluentSystemIcons.ic_fluent_history_filled;
      default:
        return Icons.insert_drive_file;
    }
  }

  Widget _buildEmptyState(String category) {
    IconData icon;
    String message;
    switch (category) {
      case 'Notes':
        icon = FluentSystemIcons.ic_fluent_document_regular;
        message = 'No downloaded notes';
        break;
      case 'Videos':
        icon = FluentSystemIcons.ic_fluent_video_clip_regular;
        message = 'No downloaded videos';
        break;
      case 'Past Questions':
        icon = FluentSystemIcons.ic_fluent_history_filled;
        message = 'No downloaded past questions';
        break;
      default:
        icon = Icons.file_present;
        message = 'No downloads found';
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
              'Your downloaded ${category.toLowerCase()} will appear here for offline access.',
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

  void _showFileOptions(ds.DownloadedResource file) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              const SizedBox(height: 8),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // File Info Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppStyles.accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getIconForFile(file.fileType),
                        color: AppStyles.accentColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.fileName,
                            style: const TextStyle(
                              color: AppStyles.headingColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatSize(file.size),
                            style: const TextStyle(
                              color: AppStyles.mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Divider(color: AppStyles.inputBorder),

              // Actions
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppStyles.accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FluentSystemIcons.ic_fluent_open_filled,
                    color: AppStyles.accentColor,
                    size: 18,
                  ),
                ),
                title: const Text(
                  'Open File',
                  style: TextStyle(
                    color: AppStyles.headingColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await OpenFilex.open(file.localPath);
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppStyles.accentColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    FluentSystemIcons.ic_fluent_share_filled,
                    color: AppStyles.accentColor,
                    size: 18,
                  ),
                ),
                title: const Text(
                  'Share File',
                  style: TextStyle(
                    color: AppStyles.headingColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final params = ShareParams(
                      text: 'Check out this file: ${file.fileName}',
                      files: [XFile(file.localPath)],
                      title: 'Share File',
                    );

                    final result = await SharePlus.instance.share(params);

                    if (!context.mounted) return;
                    if (result.status == ShareResultStatus.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('File shared successfully!'),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to share file: $e')),
                    );
                  }
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    FluentSystemIcons.ic_fluent_delete_filled,
                    color: Colors.red,
                    size: 18,
                  ),
                ),
                title: const Text(
                  'Delete File',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Text(
                        'Delete File',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: Text(
                        'Are you sure you want to delete "${file.fileName}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ds.DownloadService.removeDownload(file.localPath);
                    if (!context.mounted) return;
                    Navigator.pop(context); // close bottom sheet
                    await _loadDownloads();

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${file.fileName} deleted')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['Notes', 'Videos', 'Past Questions'];

    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppStyles.backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Downloads',
          style: AppStyles.pageTitle.copyWith(fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(FluentSystemIcons.ic_fluent_ios_arrow_left_filled),
          color: AppStyles.headingColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Segmented Capsule TabBar
          Padding(
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
          ),

          // Modern Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: AppStyles.inputTextStyle,
              decoration: AppStyles.inputDecoration(hint: _currentSearchHint)
                  .copyWith(
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
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: tabs.map((category) {
                final filtered = _downloads.where((file) {
                  String expectedType;
                  switch (category) {
                    case 'Notes':
                      expectedType = 'note';
                      break;
                    case 'Videos':
                      expectedType = 'video';
                      break;
                    case 'Past Questions':
                      expectedType = 'past_question';
                      break;
                    default:
                      expectedType = '';
                  }
                  final matchType = file.fileType == expectedType;
                  final matchQuery = file.fileName.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                  return matchType && matchQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(category);
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final file = filtered[i];
                    final icon = _getIconForFile(file.fileType);
                    final sizeText = _formatSize(file.size);
                    final timeText = _formatDate(file.downloadedAt);

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
                              file.fileName,
                              style: TextStyle(
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
                                "$sizeText • $timeText",
                                style: const TextStyle(
                                  color: AppStyles.mutedText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            trailing: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                icon: Icon(
                                  Icons.more_horiz_rounded,
                                  color: AppStyles.iconMuted,
                                ),
                                onPressed: () => _showFileOptions(file),
                              ),
                            ),
                            onTap: () async {
                              await OpenFilex.open(file.localPath);
                            },
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
