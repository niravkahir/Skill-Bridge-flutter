import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/app_bar.dart';
import '../../screens/student/profile_screen.dart';
import '../../screens/student/edit_profile_screen.dart';
import '../../screens/student/add_skill_screen.dart';
import '../../screens/student/search_screen.dart';

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
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profile = Provider.of<ProfileProvider>(context, listen: false);
      if (auth.user != null) profile.loadProfile(auth.user!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (!auth.isAuthenticated) return const SizedBox.shrink();

    return Scaffold(
      // ✅ Pass tab info so dropdown can switch tabs
      appBar: ProfessionalAppBar(
        currentTab: _selectedIndex,
        onTabSelect: (i) => setState(() => _selectedIndex = i),
      ),
      body: SafeArea(child: _getBody(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
    );
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return _buildHome();
      case 1:
      // ✅ No AppBar — HomeScreen already provides it
        return const ProfileScreen();
      case 2:
      // ✅ No AppBar — HomeScreen already provides it
        return const SearchScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHome() {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = provider.profile;
        final name = profile?.fullName ?? 'User';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Welcome back,',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.8), fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _pill(profile?.college ?? 'No College'),
                        _pill('Semester ${profile?.semester ?? 1}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _statCard('Teaching',
                      provider.teachSkillsWithDetails.length.toString(),
                      Icons.school),
                  const SizedBox(width: 12),
                  _statCard('Learning',
                      provider.learnSkillsWithDetails.length.toString(),
                      Icons.book),
                  const SizedBox(width: 12),
                  _statCard(
                      'Status',
                      provider.isVerified ? 'Verified' : 'Pending',
                      Icons.verified,
                      iconColor:
                      provider.isVerified ? Colors.green : Colors.orange),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 24) / 3;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _actionCard('Edit Profile', Icons.edit, cardWidth, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()),
                        ).then((_) {
                          final auth =
                          Provider.of<AuthProvider>(context, listen: false);
                          provider.loadProfile(auth.user!.id);
                        });
                      }),
                      _actionCard('Add Skills', Icons.add_circle, cardWidth, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AddSkillScreen()),
                        ).then((_) {
                          final auth =
                          Provider.of<AuthProvider>(context, listen: false);
                          provider.loadProfile(auth.user!.id);
                        });
                      }),
                      _actionCard('Find Students', Icons.search, cardWidth, () {
                        setState(() => _selectedIndex = 2);
                      }),
                      _actionCard('My Meetings', Icons.video_call, cardWidth, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Meetings - Coming Soon')),
                        );
                      }),
                      _actionCard('Reviews', Icons.star, cardWidth, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reviews - Coming Soon')),
                        );
                      }),
                      _actionCard('Requests', Icons.mail, cardWidth, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Requests - Coming Soon')),
                        );
                      }),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pill(String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text,
        style: TextStyle(
            color: Colors.white.withOpacity(0.9), fontSize: 14)),
  );

  Widget _statCard(String label, String value, IconData icon,
      {Color? iconColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 28),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label,
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(
      String title, IconData icon, double width, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: width,
        height: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 30),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}