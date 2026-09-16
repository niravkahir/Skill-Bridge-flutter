import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/profile/profile_picture.dart';

class SendRequestScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final List<Map<String, dynamic>> teachSkills;

  const SendRequestScreen({
    super.key,
    required this.studentData,
    required this.teachSkills,
  });

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _timeController = TextEditingController();
  String? _selectedSkillId;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSkillId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a skill')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final requestProvider =
      Provider.of<RequestProvider>(context, listen: false);

      final success = await requestProvider.sendRequest(
        senderId: auth.user!.id,
        receiverId: widget.studentData['user_id'],
        skillId: _selectedSkillId!,
        message: _messageController.text.trim(),
        preferredTime: _timeController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request sent successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(requestProvider.error ?? 'Failed to send'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.studentData;

    return Scaffold(
      appBar: AppBar(title: const Text('Send Learning Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teacher preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.textHint.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    ProfilePicture(
                      imageUrl: s['profile_image'],
                      size: 56,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['full_name'] ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${s['college'] ?? ''} • Sem ${s['semester'] ?? 1}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Skill dropdown
              const Text(
                'Which skill do you want to learn?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedSkillId,
                isExpanded: true,
                decoration: InputDecoration(
                  hintText: 'Select a skill',
                  prefixIcon: const Icon(Icons.school),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: widget.teachSkills
                    .map((s) => DropdownMenuItem<String>(
                  value: s['skill_id'] as String,
                  child: Text(
                    s['skill_name'] ?? 'Unknown',
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _selectedSkillId = v),
                validator: (v) => v == null ? 'Please select a skill' : null,
              ),
              const SizedBox(height: 20),

              // Message
              const Text(
                'Why do you want to learn this?',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _messageController,
                maxLines: 4,
                minLines: 3,
                decoration: InputDecoration(
                  hintText:
                  'Tell them about your goal, current level, why you need help...',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please write a message';
                  }
                  if (v.trim().length < 20) {
                    return 'Message must be at least 20 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Preferred time
              const Text(
                'Preferred time (optional)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  hintText: 'e.g., Weekends, evenings after 6 PM',
                  prefixIcon: const Icon(Icons.access_time),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 32),

              // Send button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _send,
                  icon: _isSending
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                      : const Icon(
                    Icons.send,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  label: Text(
                    _isSending ? 'Sending...' : 'Send Request',
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
      ),
    );
  }
}