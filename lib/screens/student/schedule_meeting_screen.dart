import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/profile/profile_picture.dart';

class ScheduleMeetingScreen extends StatefulWidget {
  final Map<String, dynamic> requestData; // accepted request

  const ScheduleMeetingScreen({
    super.key,
    required this.requestData,
  });

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  int _durationMinutes = 30;
  bool _isScheduling = false;

  // Compute end time
  TimeOfDay? get _endTime {
    if (_startTime == null) return null;
    final totalMinutes = _startTime!.hour * 60 + _startTime!.minute + _durationMinutes;
    return TimeOfDay(
      hour: (totalMinutes ~/ 60) % 24,
      minute: totalMinutes % 60,
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final now = DateTime.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay(hour: now.hour + 1, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _scheduleMeeting() async {
    if (_selectedDate == null) {
      _showError('Please select a date');
      return;
    }
    if (_startTime == null) {
      _showError('Please select start time');
      return;
    }

    // Validate time is in future
    final startDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );

    if (startDateTime.isBefore(DateTime.now().add(const Duration(minutes: 30)))) {
      _showError('Meeting must be at least 30 minutes from now');
      return;
    }

    setState(() => _isScheduling = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final meetingProvider =
      Provider.of<MeetingProvider>(context, listen: false);

      // Get IDs from request
      final isTeacher = widget.requestData['receiver_id'] == auth.user!.id;
      final teacherId = isTeacher
          ? auth.user!.id
          : widget.requestData['receiver_id'];
      final learnerId = isTeacher
          ? widget.requestData['sender_id']
          : auth.user!.id;

      final meetingId = await meetingProvider.scheduleMeeting(
        requestId: widget.requestData['id'],
        teacherId: teacherId,
        learnerId: learnerId,
        skillId: widget.requestData['skill_id'],
        skillName: widget.requestData['skill_name'] ?? 'Session',
        meetingDate: _selectedDate!,
        startTime: _formatTime(_startTime!),
        endTime: _formatTime(_endTime!),
        durationMinutes: _durationMinutes,
      );

      if (!mounted) return;

      if (meetingId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Meeting scheduled! Zoom link created.'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      } else {
        _showError(meetingProvider.error ?? 'Failed to schedule meeting');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isScheduling = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.requestData;
    final isTeacher =
        r['receiver_id'] == Provider.of<AuthProvider>(context).user?.id;
    final otherName = isTeacher ? r['sender_name'] : r['receiver_name'];
    final otherImage = isTeacher ? r['sender_image'] : r['receiver_image'];
    final otherCollege =
    isTeacher ? r['sender_college'] : r['receiver_college'];
    final otherSemester =
    isTeacher ? r['sender_semester'] : r['receiver_semester'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Meeting'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============ WHO YOU'RE MEETING ============
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
                  ProfilePicture(imageUrl: otherImage, size: 56),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          otherName ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$otherCollege • Sem $otherSemester',
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
            const SizedBox(height: 16),

            // ============ SKILL BADGE ============
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    r['skill_name'] ?? 'Skill',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ============ DATE ============
            const Text(
              'Select Date',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDate == null
                        ? AppColors.textHint.withOpacity(0.3)
                        : AppColors.primary,
                    width: _selectedDate == null ? 1 : 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'Pick a date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate == null
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                        fontWeight: _selectedDate == null
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ============ START TIME ============
            const Text(
              'Start Time',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickStartTime,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _startTime == null
                        ? AppColors.textHint.withOpacity(0.3)
                        : AppColors.primary,
                    width: _startTime == null ? 1 : 2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(
                      _startTime == null
                          ? 'Pick a start time'
                          : _formatTime(_startTime!),
                      style: TextStyle(
                        fontSize: 16,
                        color: _startTime == null
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                        fontWeight: _startTime == null
                            ? FontWeight.normal
                            : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ============ DURATION ============
            const Text(
              'Duration',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _durationChip(30, '30 min'),
                const SizedBox(width: 8),
                _durationChip(60, '1 hour'),
                const SizedBox(width: 8),
                _durationChip(90, '1.5 hours'),
              ],
            ),
            const SizedBox(height: 24),

            // ============ SUMMARY ============
            if (_selectedDate != null && _startTime != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Summary',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📅 ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}\n'
                          '🕒 ${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}\n'
                          '⏱️ $_durationMinutes minutes\n'
                          '🎥 Zoom link will be generated automatically',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // ============ SCHEDULE BUTTON ============
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isScheduling ? null : _scheduleMeeting,
                icon: _isScheduling
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                )
                    : const Icon(
                  Icons.video_call,
                  color: AppColors.primary,
                  size: 22,
                ),
                label: Text(
                  _isScheduling ? 'Creating Zoom Meeting...' : 'Schedule Meeting',
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
    );
  }

  Widget _durationChip(int minutes, String label) {
    final isActive = _durationMinutes == minutes;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _durationMinutes = minutes),
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
                color: isActive
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontWeight:
                isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}