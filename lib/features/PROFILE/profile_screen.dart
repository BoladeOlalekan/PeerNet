import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peer_net/base/routing/route_names.dart';
import 'package:peer_net/features/AUTH/data/auth_repository.dart';
import 'package:peer_net/base/res/styles/app_styles.dart';
import 'package:peer_net/features/AUTH/application/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authRepository = ref.watch(authRepositoryProvider);
    final authState = ref.watch(authControllerProvider);
    final user = authState.user.value;

    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Profile",
                    style: AppStyles.pageTitle.copyWith(fontSize: 32),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ======= User Info Card =======
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppStyles.primaryColor,
                            AppStyles.primaryColor.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppStyles.primaryColor.withValues(
                              alpha: 0.3,
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
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage:
                                  (user?.avatarUrl ?? '').isNotEmpty
                                  ? CachedNetworkImageProvider(user!.avatarUrl!)
                                  : const NetworkImage(
                                          "https://lh3.googleusercontent.com/aida-public/AB6AXuAtUmPCV6_iCOw7mfIDLIbHfyRdhGLNhWrGUWwKzn10lTqztThDu-icL7IiAM75CLZHodix_8vcv77mkcS22DlZWH3GF6agpNnWFM56lErAWXkkILztdTCEadhGWfSyRkAgXp33mRtDq_uYzSceLJmsJ3TLKmiIBQzsfUQ-F9bI4u5iIkhyMDqiQ8_PQL8-B_pBDgmUKDDusHVyuvibsO9n39azqEzIskQ-uQ7T_N_gAEI9eacxj6NEdq_P0AVrkN-GoZpx7C7CZmQ",
                                        )
                                        as ImageProvider,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? "User",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ?? "",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GestureDetector(
                                  onTap: () =>
                                      context.push(RouteNames.editProfile),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          FluentSystemIcons
                                              .ic_fluent_edit_regular,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Edit Profile",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ======= Content =======
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        "CONTENT",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppStyles.mutedText,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildMenuGroup([
                      _ActionItemData(
                        icon: FluentSystemIcons.ic_fluent_cloud_backup_regular,
                        label: "My Uploads",
                        onTap: () => context.push(RouteNames.myUploads),
                      ),
                      _ActionItemData(
                        icon:
                            FluentSystemIcons.ic_fluent_arrow_download_regular,
                        label: "Downloads",
                        onTap: () => context.push(RouteNames.downloads),
                      ),
                    ]),

                    const SizedBox(height: 28),

                    // ======= Preferences =======
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        "PREFERENCES",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppStyles.mutedText,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildMenuGroup([
                      _ActionItemData(
                        icon: FluentSystemIcons.ic_fluent_shield_regular,
                        label: "Privacy Settings",
                        onTap: () {},
                      ),
                    ]),

                    const SizedBox(height: 28),

                    // ======= Account =======
                    Padding(
                      padding: const EdgeInsets.only(left: 8, bottom: 12),
                      child: Text(
                        "ACCOUNT",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppStyles.mutedText,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildMenuGroup([
                      _ActionItemData(
                        icon: FluentSystemIcons.ic_fluent_sign_out_regular,
                        label: "Log Out",
                        onTap: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text(
                                'Sign Out',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              content: const Text(
                                'Are you sure you want to sign out?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Sign Out'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await authRepository.signOut();
                            if (context.mounted) {
                              context.go(
                                RouteNames.auth,
                                extra: {'showSignUp': false},
                              );
                            }
                          }
                        },
                        isDestructive: true,
                      ),
                      _ActionItemData(
                        icon: FluentSystemIcons.ic_fluent_delete_regular,
                        label: "Delete Account",
                        onTap: () {},
                        isDestructive: true,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGroup(List<_ActionItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppStyles.inputBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(24) : Radius.zero,
                  bottom: isLast ? const Radius.circular(24) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: item.isDestructive
                              ? Colors.red.withValues(alpha: 0.1)
                              : AppStyles.accentColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          size: 20,
                          color: item.isDestructive
                              ? Colors.red
                              : AppStyles.accentColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: item.isDestructive
                                ? Colors.red
                                : AppStyles.headingColor,
                          ),
                        ),
                      ),
                      Icon(
                        FluentSystemIcons.ic_fluent_chevron_right_regular,
                        size: 20,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                Padding(
                  padding: const EdgeInsets.only(left: 60, right: 20),
                  child: Divider(height: 1, color: Colors.grey.shade200),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ActionItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  _ActionItemData({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });
}
