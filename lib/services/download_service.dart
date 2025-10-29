import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class DownloadedResource {
  final String fileName;
  final String fileType;
  final String localPath;
  final String originalUrl;
  final int? size;
  final int downloadedAt;

  DownloadedResource({
    required this.fileName,
    required this.fileType,
    required this.localPath,
    required this.originalUrl,
    this.size,
    int? downloadedAt,
  }) : downloadedAt = downloadedAt ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, dynamic> toJson() => {
        'fileName': fileName,
        'fileType': fileType,
        'localPath': localPath,
        'originalUrl': originalUrl,
        'size': size,
        'downloadedAt': downloadedAt,
      };

  static DownloadedResource fromJson(Map<String, dynamic> j) => DownloadedResource(
        fileName: j['fileName'],
        fileType: j['fileType'],
        localPath: j['localPath'],
        originalUrl: j['originalUrl'],
        size: j['size'] == null ? null : (j['size'] as num).toInt(),
        downloadedAt: j['downloadedAt'],
      );
}

class DownloadService {
  static const _prefsKey = 'downloaded_resources';

  static Future<Directory> _downloadDirectory(String category) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/downloads/$category');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // Downloads and persists metadata. Returns the saved resource.
  static Future<DownloadedResource> downloadResource({
    required String url,
    required String fileName,
    required String fileType,
    void Function(double progress)? onProgress, // unused with http.get, kept for API
  }) async {
    final uri = Uri.parse(url);

    final resp = await http.get(uri);
    if (resp.statusCode != 200) throw Exception('Failed to download: ${resp.statusCode}');

    final dir = await _downloadDirectory(fileType);
    final safeName = fileName.replaceAll(RegExp(r'[\/\\]'), '_');
    final filePath = '${dir.path}/$safeName';
    final file = File(filePath);
    await file.writeAsBytes(resp.bodyBytes, flush: true);

    final resource = DownloadedResource(
      fileName: fileName,
      fileType: fileType,
      localPath: filePath,
      originalUrl: url,
      size: resp.bodyBytes.length,
    );

    await _saveMeta(resource);
    return resource;
  }

  static Future<void> _saveMeta(DownloadedResource r) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];
    // avoid duplicates by localPath
    final list = raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    final exists = list.any((m) => m['localPath'] == r.localPath);
    if (!exists) {
      list.add(r.toJson());
      final out = list.map((m) => jsonEncode(m)).toList();
      await prefs.setStringList(_prefsKey, out);
    }
  }

  static Future<List<DownloadedResource>> getAllDownloads() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];
    return raw.map((e) => DownloadedResource.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  static Future<List<DownloadedResource>> getDownloadsByCategory(String category) async {
    final all = await getAllDownloads();
    return all.where((r) => r.fileType == category).toList();
  }

  static Future<void> removeDownload(String localPath) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? <String>[];
    final filtered = raw.where((e) {
      final m = jsonDecode(e) as Map<String, dynamic>;
      return m['localPath'] != localPath;
    }).toList();
    await prefs.setStringList(_prefsKey, filtered);
    try {
      final f = File(localPath);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}