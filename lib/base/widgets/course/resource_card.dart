import 'package:flutter/material.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:http/http.dart' as http;

class ResourceCard extends StatefulWidget {
  final String fileName;
  final String fileType;
  final String downloadUrl;

  const ResourceCard({
    super.key,
    required this.fileName,
    required this.fileType,
    required this.downloadUrl,
  });

  @override
  State<ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends State<ResourceCard> {
  late final Future<Map<String, String?>> _metaFuture;

  @override
  void initState() {
    super.initState();
    _metaFuture = _fetchMetadata();
  }

  Future<Map<String, String?>> _fetchMetadata() async {
    try {
      if (widget.downloadUrl.isEmpty) return {'size': null, 'content-type': null};
      final uri = Uri.parse(widget.downloadUrl);
      final res = await http.head(uri);
      final contentType = res.headers['content-type'];
      final contentLength = res.headers['content-length'];
      return {'size': contentLength, 'content-type': contentType};
    } catch (_) {
      return {'size': null, 'content-type': null};
    }
  }

  String _readableSize(String? bytesStr) {
    if (bytesStr == null) return 'Unknown';
    try {
      final bytes = int.parse(bytesStr);
      if (bytes < 1024) return '$bytes B';
      final kb = bytes / 1024;
      if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
      final mb = kb / 1024;
      return '${mb.toStringAsFixed(2)} MB';
    } catch (_) {
      return 'Unknown';
    }
  }

  IconData _getFluentIconForType(String? mime) {
    final fileType = widget.fileType;
    if (mime != null && mime.startsWith('image/')) {
      return FluentSystemIcons.ic_fluent_image_regular;
    }

    switch (fileType) {
      case 'note':
        return FluentSystemIcons.ic_fluent_document_regular;
      case 'past_question':
        return FluentSystemIcons.ic_fluent_history_filled;
      case 'video':
        return FluentSystemIcons.ic_fluent_video_clip_regular;
      default:
        return FluentSystemIcons.ic_fluent_document_regular;
    }
  }

  bool _isImage(String? mime) {
    if (mime != null) return mime.startsWith('image/');
    final ext = widget.fileName.split('.').last.toLowerCase();
    return ['png', 'jpg', 'jpeg', 'gif', 'webp'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview area
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: FutureBuilder<Map<String, String?>>(
                future: _metaFuture,
                builder: (context, snap) {
                  final meta = snap.data;
                  final mime = meta?['content-type'];
                  if (_isImage(mime)) {
                    if (widget.downloadUrl.isEmpty) {
                      return Container(
                        color: Colors.grey[100], 
                        child: const Icon(
                          FluentSystemIcons.ic_fluent_image_regular, 
                          size: 48
                        )
                      );
                    }
                    return Image.network(
                      widget.downloadUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: Icon(_getFluentIconForType(mime), size: 48, color: AppStyles.primaryColor),
                        ),
                      ),
                    );
                  }

                  // non-image preview: icon + extension label
                  final icon = _getFluentIconForType(mime);
                  final ext = widget.fileName.contains('.') ? widget.fileName.split('.').last.toUpperCase() : '';
                  return Container(
                    color: AppStyles.accentColor.withValues(alpha: 0.06),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 44, color: AppStyles.accentColor),
                          if (ext.isNotEmpty) const SizedBox(height: 8),
                          if (ext.isNotEmpty) Text(ext, style: TextStyle(color: AppStyles.accentColor.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Footer with name and actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppStyles.subStyle.copyWith(
                    fontWeight: FontWeight.w400
                  ),
                ),
                
                FutureBuilder<Map<String, String?>>(
                  future: _metaFuture,
                  builder: (context, snap) {
                    final sizeStr = _readableSize(snap.data?['size']);
                    return Text('Size: $sizeStr');
                  },
                ),

                SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(FluentSystemIcons.ic_fluent_info_regular),
                      color: AppStyles.accentColor,
                      onPressed: () async {
                        final meta = await _metaFuture;
                        final size = _readableSize(meta['size']);
                        final type = meta['content-type'] ?? widget.fileType;
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('File info'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Name: ${widget.fileName}'),
                                const SizedBox(height: 6),
                                Text('Type: $type'),
                                const SizedBox(height: 6),
                                Text('Size: $size'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(dialogContext).pop(),
                                child: const Text('Close'),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(FluentSystemIcons.ic_fluent_arrow_download_regular),
                      color: AppStyles.accentColor,
                      onPressed: () async {
                        if (widget.downloadUrl.isEmpty) return;
                        final uri = Uri.parse(widget.downloadUrl);
                        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch download url')));
                        }
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
