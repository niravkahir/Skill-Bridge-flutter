import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';

class ProfessionalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool showBack;
  final int? currentTab;           // 0=Home, 1=Profile, 2=Search
  final Function(int)? onTabSelect; // Callback to switch tab

  const ProfessionalAppBar({
    super.key,
    this.showBack = false,
    this.currentTab,
    this.onTabSelect,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  void _logout(BuildContext context) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await auth.logout();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                Navigator.pushAndRemoveUntil(
                  ctx,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _switchTab(BuildContext context, int index) {
    if (onTabSelect != null) {
      onTabSelect!(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isAdmin = auth.user?.role == 'admin';
    final showTabOptions = onTabSelect != null;

    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.textPrimary,
      automaticallyImplyLeading: showBack,
      titleSpacing: showBack ? 0 : 16,
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Skill Bridge',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Learn · Teach · Grow',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            switch (value) {
              case 'home':
                _switchTab(context, 0);
                break;
              case 'profile':
                _switchTab(context, 1);
                break;
              case 'search':
                _switchTab(context, 2);
                break;
              case 'admin':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
                break;
              case 'logout':
                _logout(context);
                break;
            }
          },
          itemBuilder: (context) => [
            // Show tab options only when inside HomeScreen
            if (showTabOptions) ...[
              PopupMenuItem(
                value: 'home',
                child: Row(
                  children: [
                    Icon(
                      Icons.home,
                      size: 20,
                      color: currentTab == 0 ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Home',
                      style: TextStyle(
                        color: currentTab == 0 ? AppColors.primary : null,
                        fontWeight:
                        currentTab == 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 20,
                      color: currentTab == 1 ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Profile',
                      style: TextStyle(
                        color: currentTab == 1 ? AppColors.primary : null,
                        fontWeight:
                        currentTab == 1 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'search',
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      size: 20,
                      color: currentTab == 2 ? AppColors.primary : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search',
                      style: TextStyle(
                        color: currentTab == 2 ? AppColors.primary : null,
                        fontWeight:
                        currentTab == 2 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],
            if (isAdmin) ...[
              const PopupMenuItem(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings,
                        size: 20, color: AppColors.primary),
                    SizedBox(width: 12),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
            ],
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20, color: AppColors.error),
                  SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}