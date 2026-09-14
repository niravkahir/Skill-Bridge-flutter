import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/skill_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/common/app_bar.dart';
import 'other_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool showAppBar;

  const SearchScreen({super.key, this.showAppBar = false});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final FirestoreService _firestore = FirestoreService();
  String? _selectedSkillId;
  String? _selectedCollege;
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SkillProvider>(context, listen: false).loadSkills();
    });
  }

  Future<void> _search() async {
    setState(() => _isLoading = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.user!.id;

    try {
      List<Map<String, dynamic>> results;

      if (_selectedSkillId != null && _selectedSkillId!.isNotEmpty) {
        results = await _firestore.searchStudentsBySkill(
          skillId: _selectedSkillId!,
          currentUserId: currentUserId,
        );
      } else {
        results = await _firestore.getAllStudents(currentUserId);
      }

      if (_selectedCollege != null && _selectedCollege!.isNotEmpty) {
        results = results
            .where((s) => (s['college'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_selectedCollege!.toLowerCase()))
            .toList();
      }

      setState(() => _results = results);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Search failed: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skillProvider = Provider.of<SkillProvider>(context);

    final content = Column(
      children: [
        // ==================== FILTERS ====================
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedSkillId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Filter by Skill',
                  prefixIcon: const Icon(Icons.school),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  const DropdownMenuItem<String>(
                      value: null, child: Text('All Skills')),
                  ...skillProvider.allSkills
                      .map((s) => DropdownMenuItem<String>(
                    value: s['id'] as String,
                    child: Text(
                      s['name'] ?? '',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ))
                      .toList(),
                ],
                onChanged: (v) => setState(() => _selectedSkillId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                onChanged: (v) =>
                    setState(() => _selectedCollege = v.isEmpty ? null : v),
                decoration: InputDecoration(
                  labelText: 'Filter by College',
                  prefixIcon: const Icon(Icons.location_city),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // ✅ FIXED: Search Students button — matches Edit Profile style
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _search,
                  icon: const Icon(
                    Icons.search,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  label: Text(
                    _isLoading ? 'Searching...' : 'Search Students',
                    style: const TextStyle(
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
            ],
          ),
        ),

        // ==================== RESULTS ====================
        Expanded(
          child: _results.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search,
                    size: 80, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text('Search for students by skill or college',
                    style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _results.length,
            itemBuilder: (context, i) => _studentTile(_results[i]),
          ),
        ),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: const ProfessionalAppBar(showBack: true),
        body: content,
      );
    }

    return content;
  }

  Widget _studentTile(Map<String, dynamic> s) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          radius: 28,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: (s['profile_image'] != null &&
              s['profile_image'].toString().isNotEmpty)
              ? NetworkImage(s['profile_image'])
              : null,
          child: (s['profile_image'] == null ||
              s['profile_image'].toString().isEmpty)
              ? Icon(Icons.person, color: AppColors.primary, size: 30)
              : null,
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                s['full_name'] ?? 'Unknown',
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (s['verification_status'] == 'verified') ...[
              const SizedBox(width: 6),
              const Icon(Icons.verified, color: Colors.blue, size: 18),
            ],
          ],
        ),
        subtitle: Text('${s['college'] ?? ''} • Sem ${s['semester'] ?? 1}'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          // Show loading
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );

          try {
            final allSkills =
            await _firestore.getUserSkillsWithDetails(s['user_id']);

            final teachOnly =
            allSkills.where((sk) => sk['type'] == 'teach').toList();
            final learnOnly =
            allSkills.where((sk) => sk['type'] == 'learn').toList();

            if (!context.mounted) return;
            Navigator.pop(context);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OtherProfileScreen(
                  studentData: s,
                  teachSkills: teachOnly,
                  learnSkills: learnOnly,
                ),
              ),
            );
          } catch (e) {
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to load skills: $e')),
            );
          }
        },
      ),
    );
  }
}