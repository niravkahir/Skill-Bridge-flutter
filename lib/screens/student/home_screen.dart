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
import '../../screens/student/requests_screen.dart';
import '../../screens/student/meetings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Wait a moment for Firebase to restore session on web
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    // If user is logged in → load profile
    if (auth.user != null) {
      await profile.loadProfile(auth.user!.id);
    }

    if (mounted) {
      setState(() => _initialLoadDone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    // ✅ Show loading while checking auth
    if (!_initialLoadDone) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ If NOT authenticated → redirect to login
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ✅ Authenticated → show home
    return Scaffold(
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
        return const ProfileScreen();
      case 2:
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
              // Welcome card
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
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16)),
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

              // Stats row
              Row(
                children: [
                  _statCard(
                    label: 'Rating',
                    value: provider.reviewCount > 0
                        ? '${provider.averageRating.toStringAsFixed(1)} ★'
                        : '—',
                    icon: Icons.star,
                    iconColor: Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    label: 'Taught',
                    value: provider.taughtCount.toString(),
                    icon: Icons.school,
                    iconColor: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  _statCard(
                    label: 'Learned',
                    value: provider.learnedCount.toString(),
                    icon: Icons.book,
                    iconColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick actions
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
                      _actionCard('Edit Profile', Icons.edit, cardWidth, () async {
                        final auth =
                        Provider.of<AuthProvider>(context, listen: false);
                        final userId = auth.user!.id;
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfileScreen()),
                        );
                        if (mounted) provider.loadProfile(userId);
                      }),
                      _actionCard('Add Skills', Icons.add_circle, cardWidth,
                              () async {
                            final auth =
                            Provider.of<AuthProvider>(context, listen: false);
                            final userId = auth.user!.id;
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AddSkillScreen()),
                            );
                            if (mounted) provider.loadProfile(userId);
                          }),
                      _actionCard('Find Students', Icons.search, cardWidth, () {
                        setState(() => _selectedIndex = 2);
                      }),
                      _actionCard('My Meetings', Icons.video_call, cardWidth, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MeetingsScreen(),
                          ),
                        );
                      }),
                      _actionCard('Reviews', Icons.star, cardWidth, () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Reviews - Coming Soon')),
                        );
                      }),
                      _actionCard('Requests', Icons.mail, cardWidth, () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RequestsScreen()),
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

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? AppColors.primary, size: 26),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 2),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
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