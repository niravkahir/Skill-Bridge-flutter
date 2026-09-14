import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/app_bar.dart';
import '../../widgets/profile/profile_picture.dart';
import '../../widgets/profile/verification_badge.dart';
import '../../widgets/profile/skill_chip.dart';
import '../../widgets/profile/profile_info_card.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  final bool showAppBar;

  const ProfileScreen({super.key, this.showAppBar = false});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);

    final content = profileProvider.isLoading
        ? const Center(child: CircularProgressIndicator())
        : profileProvider.profile == null
        ? Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              size: 60, color: AppColors.error),
          const SizedBox(height: 16),
          const Text('Profile not found'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              profileProvider.loadProfile(authProvider.user!.id);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    )
        : _buildContent(context, profileProvider, authProvider);

    if (showAppBar) {
      return Scaffold(
        appBar: const ProfessionalAppBar(showBack: true),
        body: content,
      );
    }

    return content;
  }

  Widget _buildContent(BuildContext context, ProfileProvider profileProvider,
      AuthProvider authProvider) {
    final profile = profileProvider.profile!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile Picture and Name
          Center(
            child: Column(
              children: [
                ProfilePicture(
                  imageUrl: profile.profileImage,
                  size: 120,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(profile.fullName,
                        style: const TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    VerificationBadge(status: profile.verificationStatus),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  profile.email ?? authProvider.user?.email ?? 'No email',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Info Cards
          ProfileInfoCard(
            icon: Icons.school,
            label: 'College',
            value: profile.college.isNotEmpty ? profile.college : 'Not set',
          ),
          const SizedBox(height: 12),
          ProfileInfoCard(
            icon: Icons.grade,
            label: 'Semester',
            value: 'Semester ${profile.semester}',
          ),
          const SizedBox(height: 12),

          // About
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.info,
                          color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Text('About Me',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  profile.bio.isNotEmpty ? profile.bio : 'No bio set yet.',
                  style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Skills
          _skillSection(
            title: '🛠️ Skills I Can Teach',
            skills: profileProvider.teachSkillsWithDetails,
            onRemove: (id) async {
              await profileProvider.removeSkill(id);
              profileProvider.loadProfile(authProvider.user!.id);
            },
          ),
          const SizedBox(height: 16),
          _skillSection(
            title: '📚 Skills I Want to Learn',
            skills: profileProvider.learnSkillsWithDetails,
            onRemove: (id) async {
              await profileProvider.removeSkill(id);
              profileProvider.loadProfile(authProvider.user!.id);
            },
          ),
          const SizedBox(height: 24),

          // ✅ FIXED: Edit Profile — no stale context
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final userId = authProvider.user!.id;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const EditProfileScreen()),
                );
                if (context.mounted) {
                  profileProvider.loadProfile(userId);
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _skillSection({
    required String title,
    required List<Map<String, dynamic>> skills,
    required Function(String) onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              Text(skills.length.toString(),
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          if (skills.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No skills added yet',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 14)),
              ),
            )
          else
            Wrap(
              children: skills
                  .map((skill) => SkillChip(
                skillName: skill['skill_name'] ?? 'Unknown',
                level: skill['skill_level'] ?? 'beginner',
                onRemove: () => onRemove(skill['id']),
              ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}