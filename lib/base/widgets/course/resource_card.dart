import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:open_filex/open_filex.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/services/download_service.dart' as ds;
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class ResourceCard extends StatefulWidget {
  final String fileName;
  final String fileType;
  final String downloadUrl;
  final String youtubeUrl;

  const ResourceCard({
    super.key,
    required this.fileName,
    required this.fileType,
    required this.downloadUrl,
    required this.youtubeUrl,
  });

  @override
  State<ResourceCard> createState() => _ResourceCardState();
}

class _ResourceCardState extends State<ResourceCard> {
  late final Future<Map<String, String?>> _metaFuture;
  double? _progress;
  bool _isDownloading = false;
  bool _isDownloaded = false;

  @override
  void initState() {
    super.initState();
    _metaFuture = _fetchMetadata();
    _checkIfDownloaded();
  }

  Future<void> _checkIfDownloaded() async {
    final downloads = await ds.DownloadService.getAllDownloads();
    final exists = downloads.any(
      (d) =>
          d.originalUrl == widget.downloadUrl || d.fileName == widget.fileName,
    );
    if (mounted) setState(() => _isDownloaded = exists);
  }

  Future<Map<String, String?>> _fetchMetadata() async {
    try {
      if (widget.downloadUrl.isEmpty)
        return {'size': null, 'content-type': null};
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

  String? _getYoutubeThumbnail(String? url) {
    if (url == null || url.isEmpty) return null;
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(url);
    if (match != null && match.groupCount >= 1) {
      final videoId = match.group(1);
      return "https://img.youtube.com/vi/$videoId/hqdefault.jpg";
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview area
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: FutureBuilder<Map<String, String?>>(
                future: _metaFuture,
                builder: (context, snap) {
                  final meta = snap.data;
                  final mime = meta?['content-type'];

                  // ✅ Handle YouTube thumbnails
                  if (widget.youtubeUrl.isNotEmpty) {
                    final thumbnail = _getYoutubeThumbnail(widget.youtubeUrl);
                    print(
                      'DEBUG: youtubeUrl=${widget.youtubeUrl}, thumbnail=$thumbnail',
                    );
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        if (thumbnail != null)
                          Image.network(thumbnail, fit: BoxFit.cover)
                        else
                          Container(color: Colors.black12),
                        Center(
                          child: IconButton(
                            icon: Icon(
                              FluentSystemIcons.ic_fluent_video_clip_regular,
                              size: 50,
                            ),
                            color: AppStyles.accentColor,
                            onPressed: () async {
                              final youtubeUrl = Uri.parse(widget.youtubeUrl);
                              if (await canLaunchUrl(youtubeUrl)) {
                                await launchUrl(
                                  youtubeUrl,
                                  mode: LaunchMode.externalApplication,
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Could not open YouTube'),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  }

                  if (_isImage(mime)) {
                    if (widget.downloadUrl.isEmpty) {
                      return Container(
                        color: Colors.grey[100],
                        child: Icon(
                          FluentSystemIcons.ic_fluent_image_regular,
                          size: 48,
                        ),
                      );
                    }
                    return Image.network(
                      widget.downloadUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stack) => Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: Icon(
                            _getFluentIconForType(mime),
                            size: 48,
                            color: AppStyles.primaryColor,
                          ),
                        ),
                      ),
                    );
                  }

                  // non-image preview: icon + extension label
                  final icon = _getFluentIconForType(mime);
                  final ext = widget.fileName.contains('.')
                      ? widget.fileName.split('.').last.toUpperCase()
                      : '';
                  return Container(
                    color: AppStyles.accentColor.withValues(alpha: 0.06),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 44, color: AppStyles.accentColor),
                          if (ext.isNotEmpty) SizedBox(height: 8),
                          if (ext.isNotEmpty)
                            Text(
                              ext,
                              style: TextStyle(
                                color: AppStyles.accentColor.withValues(
                                  alpha: 0.9,
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Modern details area
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.fileName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    height: 1.2,
                  ),
                ),
                if (!(widget.fileType == 'video' &&
                    widget.youtubeUrl.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: FutureBuilder<Map<String, String?>>(
                          future: _metaFuture,
                          builder: (context, snap) {
                            final ext = widget.fileName.contains('.')
                                ? widget.fileName.split('.').last.toUpperCase()
                                : widget.fileType.toUpperCase();

                            if (snap.connectionState == ConnectionState.waiting) {
                              return Row(
                                children: [
                                  Shimmer.fromColors(
                                    baseColor: Colors.grey.shade200,
                                    highlightColor: Colors.grey.shade50,
                                    child: Container(
                                      width: 40,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' • $ext',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            }

                            final sizeStr = _readableSize(snap.data?['size']);
                            return Text(
                              '$sizeStr • $ext',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            );
                          },
                        ),
                      ),

                      // Download button / Progress
                      if (_isDownloading)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: _progress,
                                strokeWidth: 2.5,
                                color: AppStyles.primaryColor,
                                backgroundColor: AppStyles.inputBorder,
                              ),
                            ],
                          ),
                        )
                      else if (_isDownloaded)
                        Icon(
                          FluentSystemIcons.ic_fluent_checkmark_circle_filled,
                          color: AppStyles.primaryColor,
                          size: 24,
                        )
                      else
                        GestureDetector(
                          onTap: () async {
                            if (widget.downloadUrl.isEmpty) return;
                            setState(() {
                              _isDownloading = true;
                              _progress = 0.0;
                            });

                            try {
                              final resource =
                                  await ds.DownloadService.downloadResource(
                                    url: widget.downloadUrl,
                                    fileName: widget.fileName,
                                    fileType: widget.fileType,
                                    onProgress: (p) {
                                      setState(() => _progress = p);
                                    },
                                  );

                              setState(() {
                                _isDownloading = false;
                                _progress = null;
                                _isDownloaded = true;
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Downloaded: ${resource.fileName}',
                                  ),
                                ),
                              );

                              await OpenFilex.open(resource.localPath);
                            } catch (e) {
                              setState(() {
                                _isDownloading = false;
                                _progress = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Download failed'),
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              FluentSystemIcons
                                  .ic_fluent_arrow_download_regular,
                              size: 16,
                              color: AppStyles.primaryColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResourceCardSkeleton extends StatelessWidget {
  const ResourceCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade200,
              highlightColor: Colors.grey.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 50,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
