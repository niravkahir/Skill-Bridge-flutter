import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../widgets/profile/profile_picture.dart';
import '../../widgets/profile/verification_badge.dart';
import '../../widgets/profile/skill_chip.dart';

class OtherProfileScreen extends StatelessWidget {
  final Map<String, dynamic> studentData;
  final List<Map<String, dynamic>> teachSkills;
  final List<Map<String, dynamic>> learnSkills;

  const OtherProfileScreen({
    super.key,
    required this.studentData,
    required this.teachSkills,
    required this.learnSkills,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(studentData['full_name'] ?? 'Student Profile'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Send Request - Coming Soon')),
              );
            },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  ProfilePicture(
                    imageUrl: studentData['profile_image'],
                    size: 120,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        studentData['full_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      VerificationBadge(
                        status: studentData['verification_status'] ?? 'pending',
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    studentData['email'] ?? '',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // Info Cards
            _buildInfoCard(
              icon: Icons.school,
              label: 'College',
              value: studentData['college'] ?? 'Not set',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.grade,
              label: 'Semester',
              value: 'Semester ${studentData['semester'] ?? 1}',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.info,
              label: 'About',
              value: studentData['bio'] ?? 'No bio set',
            ),
            const SizedBox(height: 24),

            // Skills
            _buildSkillSection(
              title: '🛠️ Skills They Can Teach',
              skills: teachSkills,
            ),
            const SizedBox(height: 16),
            _buildSkillSection(
              title: '📚 Skills They Want to Learn',
              skills: learnSkills,
            ),
            const SizedBox(height: 24),

            // Request Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Learning request sent!'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
                icon: const Icon(Icons.send),
                label: const Text('Request Learning Session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textHint.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillSection({
    required String title,
    required List<Map<String, dynamic>> skills,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textHint.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                skills.length.toString(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (skills.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No skills added yet',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            Wrap(
              children: skills.map((skill) {
                return SkillChip(
                  skillName: skill['skill_name'] ?? 'Unknown',
                  level: skill['skill_level'] ?? 'beginner',
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}