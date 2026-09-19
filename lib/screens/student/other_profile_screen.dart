import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../../services/firestore_service.dart';
import '../../widgets/profile/profile_picture.dart';
import '../../widgets/profile/skill_chip.dart';
import 'reviews_list_screen.dart';
import 'send_request_screen.dart';

class OtherProfileScreen extends StatefulWidget {
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
  State<OtherProfileScreen> createState() => _OtherProfileScreenState();
}

class _OtherProfileScreenState extends State<OtherProfileScreen> {
  final FirestoreService _firestore = FirestoreService();

  double _averageRating = 0.0;
  int _reviewCount = 0;
  int _taughtCount = 0;
  int _learnedCount = 0;

  double _teachingRating = 0.0;
  int _teachingReviewCount = 0;
  double _learningRating = 0.0;
  int _learningReviewCount = 0;

  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final userId = widget.studentData['user_id'];
    if (userId == null) {
      setState(() => _isLoadingStats = false);
      return;
    }

    final stats = await _firestore.getUserStats(userId);
    final teachingStats = await _firestore.getTeachingRating(userId);
    final learningStats = await _firestore.getLearningRating(userId);

    if (!mounted) return;

    setState(() {
      _averageRating = (stats['average_rating'] ?? 0.0) as double;
      _reviewCount = (stats['review_count'] ?? 0) as int;
      _taughtCount = (stats['taught_count'] ?? 0) as int;
      _learnedCount = (stats['learned_count'] ?? 0) as int;
      _teachingRating = (teachingStats['average'] ?? 0.0) as double;
      _teachingReviewCount = (teachingStats['count'] ?? 0) as int;
      _learningRating = (learningStats['average'] ?? 0.0) as double;
      _learningReviewCount = (learningStats['count'] ?? 0) as int;
      _isLoadingStats = false;
    });
  }

  void _openSendRequest() {
    if (widget.teachSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This user has no skills to teach yet'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SendRequestScreen(
          studentData: widget.studentData,
          teachSkills: widget.teachSkills,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.studentData;

    return Scaffold(
      appBar: AppBar(
        title: Text(s['full_name'] ?? 'Student Profile'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Center(
              child: Column(
                children: [
                  ProfilePicture(
                    imageUrl: s['profile_image'],
                    size: 120,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          s['full_name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_reviewCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.amber),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${_averageRating.toStringAsFixed(1)} ($_reviewCount)',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s['email'] ?? '',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ============ SPLIT STATS ============
            _isLoadingStats
                ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
                : Column(
              children: [
                Row(
                  children: [
                    _statCard(
                      label: 'Teaching',
                      value: _teachingReviewCount > 0
                          ? '${_teachingRating.toStringAsFixed(1)} ★'
                          : '—',
                      icon: Icons.school,
                      iconColor: Colors.amber,
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      label: 'Learning',
                      value: _learningReviewCount > 0
                          ? '${_learningRating.toStringAsFixed(1)} ★'
                          : '—',
                      icon: Icons.book,
                      iconColor: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _statCard(
                      label: 'Taught',
                      value: _taughtCount.toString(),
                      icon: Icons.school,
                      iconColor: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    _statCard(
                      label: 'Learned',
                      value: _learnedCount.toString(),
                      icon: Icons.book,
                      iconColor: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            _infoCard(
              icon: Icons.school,
              label: 'College',
              value: s['college'] ?? 'Not set',
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.grade,
              label: 'Semester',
              value: 'Semester ${s['semester'] ?? 1}',
            ),
            const SizedBox(height: 12),
            _infoCard(
              icon: Icons.info,
              label: 'About',
              value: s['bio'] ?? 'No bio set',
            ),
            const SizedBox(height: 24),

            _skillSection(
              title: '🛠️ Skills They Can Teach',
              skills: widget.teachSkills,
            ),
            const SizedBox(height: 16),
            _skillSection(
              title: '📚 Skills They Want to Learn',
              skills: widget.learnSkills,
            ),
            const SizedBox(height: 24),

            // See Reviews
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReviewsListScreen(
                        userId: widget.studentData['user_id'],
                        userName: widget.studentData['full_name'] ?? 'User',
                        showAsOwner: false,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.star, color: Colors.amber),
                label: const Text(
                  'See Their Reviews',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Request button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _openSendRequest,
                icon: const Icon(
                  Icons.send,
                  color: AppColors.primary,
                  size: 20,
                ),
                label: const Text(
                  'Request Learning Session',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

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
              child: Text(
                value,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
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

  Widget _skillSection({
    required String title,
    required List<Map<String, dynamic>> skills,
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