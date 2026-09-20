import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/profile/profile_picture.dart';
import 'write_review_screen.dart';
import 'package:flutter/services.dart';

class MeetingDetailScreen extends StatefulWidget {
  final String meetingId;
  final Map<String, dynamic> meetingData;

  const MeetingDetailScreen({
    super.key,
    required this.meetingId,
    required this.meetingData,
  });

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  bool _isLoading = false;
  bool _hasReviewed = false;
  bool _checkingReview = true;

  @override
  void initState() {
    super.initState();
    _checkIfReviewed();
  }

  Future<void> _checkIfReviewed() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<ReviewProvider>(context, listen: false);
    final hasReviewed = await provider.hasReviewed(
      reviewerId: auth.user!.id,
      meetingId: widget.meetingId,
    );
    if (mounted) {
      setState(() {
        _hasReviewed = hasReviewed;
        _checkingReview = false;
      });
    }
  }

  Future<void> _openWriteReview() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WriteReviewScreen(
          meetingData: {
            'id': widget.meetingId,
            'other_user_id': widget.meetingData['other_user_id'],
            'other_user_name': widget.meetingData['other_user_name'],
            'other_user_image': widget.meetingData['other_user_image'],
            'other_user_college': widget.meetingData['other_user_college'],
            'other_user_semester': widget.meetingData['other_user_semester'],
          },
        ),
      ),
    );

    if (result == 'submitted') {
      setState(() => _hasReviewed = true);

      // ✅ Reload profile stats after review
      if (!mounted) return;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider =
      Provider.of<ProfileProvider>(context, listen: false);
      if (auth.user != null) {
        await profileProvider.loadProfile(auth.user!.id);
      }
    }
  }

  Future<void> _joinMeeting() async {
    final m = widget.meetingData;
    final joinUrl = (m['zoom_join_url'] ?? '').toString();
    final meetingId = (m['zoom_meeting_id'] ?? '').toString();

    if (joinUrl.isEmpty) {
      _snack('Zoom link not available', AppColors.error);
      return;
    }

    // Extract password from join_url (?pwd=...)
    final pwd = Uri.tryParse(joinUrl)?.queryParameters['pwd'] ?? '';

    // 1) Try Zoom app deep link
    if (meetingId.isNotEmpty) {
      final deepLink = Uri.parse(
        'zoommtg://zoom.us/join?confno=$meetingId'
            '${pwd.isNotEmpty ? '&pwd=$pwd' : ''}',
      );
      try {
        if (await launchUrl(deepLink,
            mode: LaunchMode.externalNonBrowserApplication)) {
          return;
        }
      } catch (e) {
        debugPrint('Zoom deep link failed: $e');
      }
    }

    // 2) Fall back to the https link in an external browser
    try {
      final ok = await launchUrl(
        Uri.parse(joinUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!ok) throw 'launchUrl returned false';
    } catch (e) {
      if (!mounted) return;
      _snack('Could not open Zoom: $e', AppColors.error);
      // 3) Last resort: let the user copy the link
      await Clipboard.setData(ClipboardData(text: joinUrl));
      _snack('Link copied — paste it in your browser', AppColors.primary);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  Future<void> _cancelMeeting() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Meeting?'),
        content: const Text(
          'The Zoom meeting will be deleted. The other person will be notified.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Cancel Meeting',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<MeetingProvider>(context, listen: false);
    final success = await provider.cancelMeeting(widget.meetingId);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting cancelled'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, 'cancelled');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to cancel'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _completeMeeting() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Completed?'),
        content: const Text(
          'Both of you can then leave feedback for each other.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Mark Complete',
              style: TextStyle(color: AppColors.success),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<MeetingProvider>(context, listen: false);
    final success = await provider.completeMeeting(widget.meetingId);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Meeting completed!'),
          backgroundColor: AppColors.success,
        ),
      );
      setState(() {
        widget.meetingData['status'] = 'completed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.meetingData;
    final isTeacher = m['is_teacher'] == true;
    final status = m['status'] ?? 'scheduled';

    DateTime meetingDate;
    try {
      meetingDate = (m['meeting_date'] as dynamic).toDate();
    } catch (_) {
      meetingDate = DateTime.now();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Details'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _statusColor(status).withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      Icon(_statusIcon(status),
                          color: _statusColor(status), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status: ${status.toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _statusColor(status),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _statusMessage(status, isTeacher),
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
                const SizedBox(height: 20),

                // Other user card
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
                          imageUrl: m['other_user_image'], size: 56),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['other_user_name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${m['other_user_college']} • Sem ${m['other_user_semester']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isTeacher
                                    ? Colors.blue.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                isTeacher
                                    ? 'You are teaching'
                                    : 'You are learning',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isTeacher
                                      ? Colors.blue
                                      : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _detailCard(
                  icon: Icons.school,
                  label: 'Skill',
                  value: m['skill_name'] ?? 'Unknown',
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value:
                  '${meetingDate.day}/${meetingDate.month}/${meetingDate.year}',
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.access_time,
                  label: 'Time',
                  value:
                  '${m['start_time'] ?? ''} - ${m['end_time'] ?? ''}',
                ),
                const SizedBox(height: 12),
                _detailCard(
                  icon: Icons.timer,
                  label: 'Topic',
                  value: m['topic'] ?? 'Session',
                ),

                if (status == 'scheduled') ...[
                  const SizedBox(height: 24),
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
                        const Row(
                          children: [
                            Icon(Icons.videocam,
                                color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Zoom Meeting',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          m['zoom_join_url'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Action buttons (scheduled)
                if (status == 'scheduled') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _joinMeeting,
                      icon: const Icon(Icons.videocam,
                          color: Colors.white, size: 22),
                      label: Text(
                        isTeacher
                            ? 'Start Meeting (Host)'
                            : 'Join Meeting',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _completeMeeting,
                      icon: const Icon(Icons.check_circle,
                          color: AppColors.success),
                      label: const Text(
                        'Mark as Completed',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side:
                        const BorderSide(color: AppColors.success),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _cancelMeeting,
                      icon: const Icon(Icons.cancel,
                          color: AppColors.error),
                      label: const Text(
                        'Cancel Meeting',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],

                // Completed → Review CTA
                if (status == 'completed') ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle,
                            color: AppColors.success, size: 40),
                        const SizedBox(height: 8),
                        const Text(
                          'Session Completed! 🎉',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (_checkingReview)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: CircularProgressIndicator(),
                          )
                        else if (_hasReviewed)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    color: AppColors.primary,
                                    size: 20),
                                SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'You have already reviewed this meeting',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: _openWriteReview,
                              icon: const Icon(Icons.star,
                                  color: Colors.white, size: 22),
                              label: const Text(
                                'Leave a Review',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Cancelled
                if (status == 'cancelled') ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.cancel,
                            color: AppColors.error, size: 40),
                        SizedBox(height: 8),
                        Text(
                          'Meeting Cancelled',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.error,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This meeting is no longer active',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: AppColors.textHint.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  String _statusMessage(String status, bool isTeacher) {
    switch (status) {
      case 'completed':
        return 'Great! Please leave feedback for your partner.';
      case 'cancelled':
        return 'This meeting has been cancelled.';
      default:
        return isTeacher
            ? 'Ready to start. Tap below when you\'re ready.'
            : 'Join the meeting when it\'s time.';
    }
  }
}