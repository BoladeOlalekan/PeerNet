import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:firebase_auth/firebase_auth.dart';

final userUploadsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final supabase = Supabase.instance.client;

  if (userId == null) return const Stream.empty();

  return supabase
      .from('uploads')
      .stream(primaryKey: ['id'])
      .eq('uploader_id', userId)
      .order('created_at', ascending: false)
      .map((rows) => rows);
});

class UserUploadsScreen extends ConsumerWidget {
  const UserUploadsScreen({super.key});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploadsAsync = ref.watch(userUploadsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Uploads'),
        centerTitle: true,
      ),
      body: uploadsAsync.when(
        data: (uploads) {
          if (uploads.isEmpty) {
            return const Center(child: Text("No uploads yet"));
          }

          return ListView.builder(
            itemCount: uploads.length,
            itemBuilder: (context, index) {
              final upload = uploads[index];
              final status = upload['status'] ?? 'pending';
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 1.5,
                child: ListTile(
                  leading: Icon(
                    Icons.insert_drive_file,
                    color: AppStyles.accentColor,
                  ),
                  title: Text(
                    upload['file_type'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    upload['course_id'] ?? 'Unknown course',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: Chip(
                    label: Text(
                      status.toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _statusColor(status),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text("Error: $e")),
      ),
    );
  }
}
