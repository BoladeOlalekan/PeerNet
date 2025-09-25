import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peer_net/base/media.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/features/AUTH/application/auth_providers.dart';
//import 'package:peer_net/features/AUTH/data/auth_repository.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.user.value;

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

            // Department & Level
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      style: AppStyles.header1,
                      children: [
                        TextSpan(text: 'Hello, '),
                        TextSpan(
                          text: user?.name ?? 'User',
                          style: AppStyles.header1.copyWith(color: accent), // 👈 different color
                        ),
                        const TextSpan(text: '👋'),
                      ],
                    ),
                  ),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppStyles.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text.rich(
                      TextSpan(
                        style: Theme.of(context).textTheme.bodyLarge, // base style
                        children: [
                          TextSpan(
                            text: 'Department: ',
                            style: const TextStyle(fontWeight: FontWeight.bold), // label bold
                          ),
                          TextSpan(
                            text: '${user?.department ?? 'Unknown'}\n', // value normal
                          ),
                          TextSpan(
                            text: 'Level: ',
                            style: const TextStyle(fontWeight: FontWeight.bold), // label bold
                          ),
                          TextSpan(
                            text: '${user?.level ?? 'N/A'}',
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // My Courses Section
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('My Courses', style: Theme.of(context).textTheme.titleMedium),
                          TextButton(onPressed: () {}, child: const Text('View All')),
                        ],
                      ),

                      // Horizontal Scroll Courses
                      SizedBox(
                        height: 140,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          itemBuilder: (context, index) => Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.book, size: 32),
                                const SizedBox(height: 8),
                                Text('Course ${index + 1}', style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Connect Section
                      Text('Connect', style: Theme.of(context).textTheme.titleMedium),
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
