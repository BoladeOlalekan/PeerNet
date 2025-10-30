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

class _DownloadsScreenState extends State<DownloadsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = ['Notes', 'Videos', 'Past Questions'];

    return Scaffold(
      appBar: AppBar(
        title:  Text('Downloads'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(FluentSystemIcons.ic_fluent_ios_arrow_left_filled),
          color: AppStyles.subText,
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppStyles.primaryColor,
          labelColor: AppStyles.primaryColor,
          unselectedLabelColor: AppStyles.subText,
          tabs: [
            for (final t in tabs) Tab(text: t),
          ],
        ),
      ),

      body: Column(
        children: [
          //Search Bar
          Padding(
            padding:  EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                prefixIcon:  Icon(FluentSystemIcons.ic_fluent_search_filled),
                hintText: _currentSearchHint,
                filled: true,
                fillColor: AppStyles.accentColor.withValues(alpha: 0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
                final matchQuery = file.fileName.toLowerCase().contains(_searchQuery.toLowerCase());
                return matchType && matchQuery;
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(category);
                }

                return ListView.builder(
                  padding:  EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final file = filtered[i];
                    final icon = _getIconForFile(file.fileType);
                    return Card(
                      color: AppStyles.borderText,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin:  EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppStyles.accentColor.withValues(alpha: 0.15),
                          child: Icon(icon, color: AppStyles.accentColor),
                        ),
                        title: Text(
                          file.fileName,
                          style: TextStyle(
                            color: AppStyles.subText, 
                            fontWeight: FontWeight.w500
                          ),
                        ),
                        subtitle: Text(
                          file.fileType.toUpperCase(),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        trailing: IconButton(
                          icon:  Icon(Icons.more_vert),
                          color: AppStyles.subText.withValues(alpha: 0.7),
                          onPressed: () => _showFileOptions(file),
                        ),
                        onTap: () async {
                          await OpenFilex.open(file.localPath);
                        },
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
        padding:  EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppStyles.accentColor.withValues(alpha: 0.4)),
             SizedBox(height: 16),
            Text(message,
              style: TextStyle(
                color: AppStyles.subText,
                fontWeight: FontWeight.w600,
                fontSize: 16
              )
            ),
            SizedBox(height: 6),
            Text(
              'Your downloaded $category will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _showFileOptions(ds.DownloadedResource file) {
    showModalBottomSheet(
      context: context,
      shape:  RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading:  Icon(
                  FluentSystemIcons.ic_fluent_open_filled,
                  color: AppStyles.accentColor
                ),
                title:  Text('Open File'),
                onTap: () async {
                  Navigator.pop(context);
                  await OpenFilex.open(file.localPath);
                },
              ),
              ListTile(
                leading: Icon(
                  FluentSystemIcons.ic_fluent_share_filled,
                  color: AppStyles.accentColor,
                ),
                title: Text('Share'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final params = ShareParams(
                      text: 'Check out this file: ${file.fileName}',
                      files: [XFile(file.localPath)],
                      title: 'Share File',
                    );

                    final result = await SharePlus.instance.share(params);

                    if (result.status == ShareResultStatus.success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('File shared successfully!')),
                      );
                    } else if (result.status == ShareResultStatus.dismissed) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share cancelled')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share failed')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Unable to share file: $e')),
                    );
                  }
                },
              ),
              ListTile(
                leading:  Icon(
                  FluentSystemIcons.ic_fluent_delete_filled,
                  color: Colors.red
                ),
                title:  Text('Delete'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete File'),
                      content: Text('Are you sure you want to delete "${file.fileName}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  // If user confirms deletion
                  if (confirm == true) {
                    await ds.DownloadService.removeDownload(file.localPath);
                    Navigator.pop(context);
                    await _loadDownloads();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${file.fileName} deleted')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
