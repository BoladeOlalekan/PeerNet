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
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Profile",
                    style: AppStyles.header1.copyWith(color: primary),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: (user?.avatarUrl ?? '').isNotEmpty
                            ? NetworkImage(user!.avatarUrl!)
                            : NetworkImage(
                              "https://lh3.googleusercontent.com/aida-public/AB6AXuAtUmPCV6_iCOw7mfIDLIbHfyRdhGLNhWrGUWwKzn10lTqztThDu-icL7IiAM75CLZHodix_8vcv77mkcS22DlZWH3GF6agpNnWFM56lErAWXkkILztdTCEadhGWfSyRkAgXp33mRtDq_uYzSceLJmsJ3TLKmiIBQzsfUQ-F9bI4u5iIkhyMDqiQ8_PQL8-B_pBDgmUKDDusHVyuvibsO9n39azqEzIskQ-uQ7T_N_gAEI9eacxj6NEdq_P0AVrkN-GoZpx7C7CZmQ",
                            ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text.rich(
                                textAlign: TextAlign.right,
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text:'${user?.name ?? "User"}\n',
                                      style: AppStyles.profileName
                                    ),
                                    TextSpan(
                                      text: user?.email ?? "",
                                      style: AppStyles.profileMail,
                                    ),
                                  ],
                                ),
                              ),
                              
                              SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  style: AppStyles.editProfileButton,
                                  onPressed: () {
                                    context.push(RouteNames.editProfile);
                                  },
                                  icon: Icon(
                                    FluentSystemIcons.ic_fluent_edit_filled,
                                    size: 16, 
                                    color: AppStyles.borderText
                                  ),
                                  label: Text(
                                    "Edit Profile",
                                    style: AppStyles.editText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 32),

                    // Action Items
                    _buildActionItem(
                      context,
                      icon: FluentSystemIcons.ic_fluent_upload_filled,
                      label: "My Uploads",
                      color: AppStyles.accentColor,
                      onTap: () {
                        context.push(RouteNames.myUploads);
                      },
                    ),
                    _buildActionItem(
                      context,
                      icon:   FluentSystemIcons.ic_fluent_cloud_download_filled,
                      label: "Downloads",
                      color:  AppStyles.accentColor,
                      onTap: () {
                        context.push(RouteNames.downloads);
                      },
                    ),
                    _buildActionItem(
                      context,
                      icon: FluentSystemIcons.ic_fluent_shield_filled,
                      label: "Privacy Settings",
                      color:  AppStyles.accentColor,
                      onTap: () {},
                    ),
                    _buildActionItem(
                      context,
                      icon: FluentSystemIcons.ic_fluent_delete_filled,
                      label: "Delete Account",
                      color: Colors.red,
                      onTap: () {},
                      isDestructive: true,
                    ),
                    _buildActionItem(
                      context,
                      icon: FluentSystemIcons.ic_fluent_sign_out_filled,
                      label: "Log Out",
                      color: Colors.red,
                      onTap: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text('Are you sure you want to sign out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Sign Out'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await authRepository.signOut();
                          if(context.mounted) {
                            context.go(
                              RouteNames.auth,
                              extra: {'showSignUp': false},
                            );
                          }
                        }
                      },
                      isDestructive: true,
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDestructive
                          ? Colors.red
                          : (Colors.black87),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right,
                    color:Colors.grey[400]),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color:   Colors.grey[300],
          ),
      ],
    );
  }
}
