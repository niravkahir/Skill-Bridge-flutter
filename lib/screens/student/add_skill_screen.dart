import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/skill_provider.dart';
import '../../models/user_skill_model.dart';

class AddSkillScreen extends StatefulWidget {
  const AddSkillScreen({super.key});

  @override
  State<AddSkillScreen> createState() => _AddSkillScreenState();
}

class _AddSkillScreenState extends State<AddSkillScreen> {
  String _selectedType = 'teach'; // 'teach' or 'learn'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SkillProvider>(context, listen: false).loadSkills();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);
    final skillProvider = Provider.of<SkillProvider>(context);

    final currentSkills = _selectedType == 'teach'
        ? profileProvider.teachSkillsWithDetails
        : profileProvider.learnSkillsWithDetails;

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Skills')),
      body: Column(
        children: [
          // Toggle between Teach / Learn
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.textHint.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                _tabButton('I Can Teach', 'teach'),
                _tabButton('I Want to Learn', 'learn'),
              ],
            ),
          ),

          // Current skills list
          Expanded(
            child: currentSkills.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.school_outlined,
                      size: 80, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No skills added yet',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + button below to add',
                    style: TextStyle(
                        color: AppColors.textHint, fontSize: 12),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: currentSkills.length,
              itemBuilder: (context, i) {
                final skill = currentSkills[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.textHint.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              skill['skill_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${skill['skill_category']} • ${skill['skill_level']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final auth = Provider.of<AuthProvider>(context,
                              listen: false);
                          await profileProvider
                              .removeSkill(skill['id']);
                          await profileProvider
                              .loadProfile(auth.user!.id);
                        },
                        icon: const Icon(Icons.delete,
                            color: AppColors.error),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSkillSheet(skillProvider, profileProvider),
        icon: const Icon(Icons.add),
        label: const Text('Add Skill'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _tabButton(String label, String type) {
    final isActive = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddSkillSheet(
      SkillProvider skillProvider,
      ProfileProvider profileProvider,
      ) async {
    // Reload skills fresh each time (in case admin just added new ones)
    await skillProvider.loadSkills();

    // Check for errors
    if (skillProvider.error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${skillProvider.error}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Check if skills exist
    if (skillProvider.allSkills.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('No skills available. Ask admin to add skills first.'),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Open bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddSkillSheet(
        type: _selectedType,
        skillProvider: skillProvider,
        profileProvider: profileProvider,
      ),
    );
  }
}

// ========================= Bottom Sheet =========================
class _AddSkillSheet extends StatefulWidget {
  final String type;
  final SkillProvider skillProvider;
  final ProfileProvider profileProvider;

  const _AddSkillSheet({
    required this.type,
    required this.skillProvider,
    required this.profileProvider,
  });

  @override
  State<_AddSkillSheet> createState() => _AddSkillSheetState();
}

class _AddSkillSheetState extends State<_AddSkillSheet> {
  String? _selectedSkillId;
  SkillLevel _selectedLevel = SkillLevel.beginner;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textHint,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.type == 'teach'
                ? 'Add Skill to Teach'
                : 'Add Skill to Learn',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Skill dropdown
          const Text('Select Skill',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSkillId,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: 'Choose a skill',
              filled: true,
              fillColor: AppColors.surface,
              border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: widget.skillProvider.allSkills
                .map((s) => DropdownMenuItem<String>(
              value: s['id'] as String,
              child: Text(
                '${s['name']} (${s['category']})',
                overflow: TextOverflow.ellipsis,
              ),
            ))
                .toList(),
            onChanged: (v) => setState(() => _selectedSkillId = v),
          ),
          const SizedBox(height: 20),

          // Skill level
          const Text('Skill Level',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _levelChip('Beginner', SkillLevel.beginner),
              const SizedBox(width: 8),
              _levelChip('Intermediate', SkillLevel.intermediate),
              const SizedBox(width: 8),
              _levelChip('Expert', SkillLevel.expert),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
                  : const Text('Add Skill',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _levelChip(String label, SkillLevel level) {
    final isActive = _selectedLevel == level;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedLevel = level),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? AppColors.primary
                  : AppColors.textHint.withOpacity(0.3),
              width: isActive ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_selectedSkillId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a skill')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await widget.profileProvider.addSkill(
      userId: auth.user!.id,
      skillId: _selectedSkillId!,
      type: widget.type,
      skillLevel: _selectedLevel,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Skill added!' : 'Failed to add skill'),
          backgroundColor: success ? AppColors.success : AppColors.error,
        ),
      );
    }
  }
}