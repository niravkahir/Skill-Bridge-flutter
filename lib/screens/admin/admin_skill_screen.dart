import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/skill_provider.dart';

class AdminSkillScreen extends StatefulWidget {
  const AdminSkillScreen({super.key});

  @override
  State<AdminSkillScreen> createState() => _AdminSkillScreenState();
}

class _AdminSkillScreenState extends State<AdminSkillScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SkillProvider>(context, listen: false)
          .loadAllSkillsForAdmin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SkillProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Skills'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.allSkills.isEmpty
          ? const Center(child: Text('No skills yet. Add one!'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.allSkills.length,
        itemBuilder: (context, i) {
          final skill = provider.allSkills[i];
          final isActive = skill['status'] == 'active';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Leading icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.school,
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),

                  // Title + subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          skill['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                skill['category'] ?? 'Uncategorized',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isActive
                                    ? AppColors.success
                                    : AppColors.error)
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(8),
                              ),
                              child: Text(
                                skill['status'] ?? 'active',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  IconButton(
                    onPressed: () => _showSkillDialog(skill),
                    icon: const Icon(Icons.edit,
                        color: AppColors.primary),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDelete(skill['id']),
                    icon: const Icon(Icons.delete,
                        color: AppColors.error),
                    iconSize: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSkillDialog(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Skill'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showSkillDialog(Map<String, dynamic>? skill) {
    final nameCtrl = TextEditingController(text: skill?['name'] ?? '');
    final catCtrl = TextEditingController(text: skill?['category'] ?? '');
    String status = skill?['status'] ?? 'active';
    final isEdit = skill != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Edit Skill' : 'Add New Skill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Skill Name',
                    hintText: 'e.g., Flutter, Python',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: catCtrl,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    hintText: 'e.g., Programming, Design',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                if (isEdit) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                          value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (v) => setDialogState(() => status = v!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty ||
                    catCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('Please fill all fields')));
                  return;
                }

                final provider =
                Provider.of<SkillProvider>(context, listen: false);
                bool success;

                if (isEdit) {
                  success = await provider.updateSkill(
                    skillId: skill['id'],
                    name: nameCtrl.text.trim(),
                    category: catCtrl.text.trim(),
                    status: status,
                  );
                } else {
                  success = await provider.addSkill(
                    name: nameCtrl.text.trim(),
                    category: catCtrl.text.trim(),
                  );
                }

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? (isEdit ? 'Skill updated' : 'Skill added')
                          : 'Failed'),
                      backgroundColor: success
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Skill?'),
        content: const Text('This will remove the skill from the system.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await Provider.of<SkillProvider>(context, listen: false)
                  .deleteSkill(id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}