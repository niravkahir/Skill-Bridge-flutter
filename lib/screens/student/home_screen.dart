import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/student/profile_screen.dart';
import '../../screens/student/edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(context, listen: false);

      if (authProvider.user != null) {
        profileProvider.loadProfile(authProvider.user!.id);
      }
    });
  }

  void _logout(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    if (!authProvider.isAuthenticated) {
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Bridge'),
        actions: [
          IconButton(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: _getBody(_selectedIndex, isTablet),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: isTablet ? BottomNavigationBarType.fixed : BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
        ],
      ),
    );
  }

  Widget _getBody(int index, bool isTablet) {
    switch (index) {
      case 0:
        return _buildHomeContent(isTablet);
      case 1:
        return const ProfileScreen();
      case 2:
        return const Center(child: Text('Search Screen - Coming Soon'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHomeContent(bool isTablet) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, child) {
        if (profileProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (profileProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Error loading profile',
                  style: TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 8),
                Text(
                  profileProvider.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    profileProvider.loadProfile(authProvider.user!.id);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final profile = profileProvider.profile;
        final fullName = profile?.fullName ?? 'No Name Set';

        return Padding(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(isTablet ? 24 : 20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: isTablet ? 18 : 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 28 : 24,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            profile?.college ?? 'No College Set',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Semester ${profile?.semester ?? 1}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isTablet ? 16 : 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Quick Stats
              Row(
                children: [
                  _buildStatCard(
                    'Teaching',
                    profileProvider.teachSkillsWithDetails.length.toString(),
                    Icons.school,
                    isTablet,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Learning',
                    profileProvider.learnSkillsWithDetails.length.toString(),
                    Icons.book,
                    isTablet,
                  ),
                  const SizedBox(width: 12),
                  _buildStatCard(
                    'Status',
                    profileProvider.isVerified ? 'Verified' : 'Pending',
                    Icons.verified,
                    isTablet,
                    iconColor: profileProvider.isVerified ? Colors.green : Colors.orange,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: isTablet ? 20 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Responsive Grid for Quick Actions
              isTablet
                  ? GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildActionCard('Edit Profile', Icons.edit, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    ).then((_) {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      profileProvider.loadProfile(authProvider.user!.id);
                    });
                  }, isTablet),
                  _buildActionCard('Add Skills', Icons.add_circle, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Skill selection coming soon!')),
                    );
                  }, isTablet),
                  _buildActionCard('Find Students', Icons.search, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Search coming soon!')),
                    );
                  }, isTablet),
                  _buildActionCard('My Meetings', Icons.video_call, () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Meetings coming soon!')),
                    );
                  }, isTablet),
                ],
              )
                  : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionCard('Edit Profile', Icons.edit, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      ).then((_) {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        profileProvider.loadProfile(authProvider.user!.id);
                      });
                    }, isTablet),
                    const SizedBox(width: 12),
                    _buildActionCard('Add Skills', Icons.add_circle, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Skill selection coming soon!')),
                      );
                    }, isTablet),
                    const SizedBox(width: 12),
                    _buildActionCard('Find Students', Icons.search, () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Search coming soon!')),
                      );
                    }, isTablet),
                    // const SizedBox(width: 12),
                    // _buildActionCard('My Meetings', Icons.video_call, () {
                    //   ScaffoldMessenger.of(context).showSnackBar(
                    //     const SnackBar(content: Text('Meetings coming soon!')),
                    //   );
                    // }, isTablet),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, bool isTablet, {Color? iconColor}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textHint.withOpacity(0.2),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: isTablet ? 32 : 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: isTablet ? 24 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: isTablet ? 14 : 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, VoidCallback onTap, bool isTablet) {
    final double cardWidth = isTablet ? 120 : 100;
    final double iconSize = isTablet ? 36 : 32;
    final double fontSize = isTablet ? 14 : 12;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: cardWidth,
        padding: EdgeInsets.all(isTablet ? 20 : 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textHint.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: iconSize),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}