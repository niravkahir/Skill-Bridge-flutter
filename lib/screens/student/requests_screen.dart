import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/profile/profile_picture.dart';
import 'meeting_detail_screen.dart';
import 'schedule_meeting_screen.dart';

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  void _reload() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<RequestProvider>(context, listen: false);
    provider.loadIncomingRequests(auth.user!.id);
    provider.loadSentRequests(auth.user!.id);
    provider.loadRequestHistory(auth.user!.id);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text(
          'Learning Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          tabs: const [
            Tab(text: 'Incoming'),
            Tab(text: 'Responded'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: Consumer<RequestProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildIncoming(provider),
              _buildHistory(provider),
              _buildSent(provider),
            ],
          );
        },
      ),
    );
  }

  // ==================== INCOMING ====================
  Widget _buildIncoming(RequestProvider provider) {
    final list = provider.incomingRequests;

    if (list.isEmpty) {
      return _emptyState(
        icon: Icons.inbox,
        message: 'No pending requests',
        subMessage: 'New requests will appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, i) => _requestCard(list[i], mode: 'incoming'),
      ),
    );
  }

  // ==================== HISTORY ====================
  Widget _buildHistory(RequestProvider provider) {
    final list = provider.requestHistory;

    if (list.isEmpty) {
      return _emptyState(
        icon: Icons.history,
        message: 'No request history',
        subMessage: 'Accepted & rejected requests appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, i) => _requestCard(list[i], mode: 'history'),
      ),
    );
  }

  // ==================== SENT ====================
  Widget _buildSent(RequestProvider provider) {
    final list = provider.sentRequests;

    if (list.isEmpty) {
      return _emptyState(
        icon: Icons.send,
        message: 'No sent requests',
        subMessage: 'Your outgoing requests appear here',
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, i) => _requestCard(list[i], mode: 'sent'),
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: AppColors.textHint),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subMessage,
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== REQUEST CARD ====================
  Widget _requestCard(Map<String, dynamic> r, {required String mode}) {
    final status = r['status'] ?? 'pending';
    final meetingStatus = r['meeting_status'];

    final bool showSender = mode == 'incoming' || mode == 'history';
    final name = showSender ? r['sender_name'] : r['receiver_name'];
    final image = showSender ? r['sender_image'] : r['receiver_image'];
    final college = showSender ? r['sender_college'] : r['receiver_college'];
    final semester =
    showSender ? r['sender_semester'] : r['receiver_semester'];

    // ✅ isTeacher declared here (top of method) — valid in Dart
    final bool isTeacher = mode == 'incoming' || mode == 'history';

    final timeSource = mode == 'history' && r['responded_at'] != null
        ? r['responded_at']
        : r['created_at'];
    final time = timeSource != null ? _formatTime(timeSource) : '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ============ HEADER ============
            Row(
              children: [
                ProfilePicture(imageUrl: image, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$college • Sem $semester',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusBadge(status),
              ],
            ),
            const SizedBox(height: 12),

            // ============ SKILL ============
            Row(
              children: [
                const Icon(Icons.school, size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  r['skill_name'] ?? 'Unknown Skill',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ============ MESSAGE ============
            Text(
              r['message'] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            // ============ PREFERRED TIME ============
            if ((r['preferred_time'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    r['preferred_time'],
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
            Text(
              mode == 'history' ? 'Responded $time' : time,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),

            // ============ PENDING ACTIONS ============
            if (mode == 'incoming' && status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _actionBtn(
                      'Reject',
                      Icons.close,
                      AppColors.error,
                          () => _updateStatus(r['id'], 'rejected'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionBtn(
                      'Accept',
                      Icons.check,
                      AppColors.success,
                          () => _updateStatus(r['id'], 'accepted'),
                    ),
                  ),
                ],
              ),
            ],

            if (mode == 'sent' && status == 'pending') ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _actionBtn(
                  'Cancel Request',
                  Icons.cancel,
                  AppColors.error,
                      () => _updateStatus(r['id'], 'cancelled'),
                ),
              ),
            ],

            // ============ ACCEPTED: MEETING FLOW ============
            if (status == 'accepted') ...[
              const SizedBox(height: 16),

              // 1. NO MEETING YET
              if (meetingStatus == null) ...[
                // Teacher sees Schedule button
                if (isTeacher)
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ScheduleMeetingScreen(requestData: r),
                          ),
                        );
                        if (result == true) _reload();
                      },
                      icon: const Icon(
                        Icons.video_call,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        'Schedule Meeting',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                // Learner sees waiting message
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.hourglass_empty,
                            color: Colors.orange, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Waiting for teacher to schedule the meeting',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              // 2. MEETING SCHEDULED → Both see View Meeting
              if (meetingStatus == 'scheduled')
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MeetingDetailScreen(
                            meetingId: r['meeting_id'],
                            meetingData: {
                              'id': r['meeting_id'],
                              'is_teacher': isTeacher,
                              'status': r['meeting_status'],
                              'skill_name': r['skill_name'],
                              'meeting_date': r['meeting_date'],
                              'start_time': r['meeting_start_time'],
                              'end_time': r['meeting_end_time'],
                              'zoom_join_url': r['zoom_join_url'],
                              'zoom_start_url': r['zoom_start_url'],
                              'other_user_name': showSender
                                  ? r['sender_name']
                                  : r['receiver_name'],
                              'other_user_image': showSender
                                  ? r['sender_image']
                                  : r['receiver_image'],
                              'other_user_college': showSender
                                  ? r['sender_college']
                                  : r['receiver_college'],
                              'other_user_semester': showSender
                                  ? r['sender_semester']
                                  : r['receiver_semester'],
                            },
                          ),
                        ),
                      );
                      if (result != null) _reload();
                    },
                    icon: const Icon(
                      Icons.videocam,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    label: const Text(
                      'View Meeting',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                      AppColors.primary.withOpacity(0.1),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

              // 3. COMPLETED → Green banner
              if (meetingStatus == 'completed')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.success.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Meeting completed successfully',
                          style: TextStyle(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 4. CANCELLED → Red banner
              if (meetingStatus == 'cancelled')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.error.withOpacity(0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel,
                          color: AppColors.error, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Meeting was cancelled',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'accepted':
        color = AppColors.success;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = AppColors.error;
        icon = Icons.cancel;
        break;
      case 'cancelled':
        color = Colors.grey;
        icon = Icons.block;
        break;
      default:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return SizedBox(
      height: 44,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatus(String requestId, String status) async {
    final provider = Provider.of<RequestProvider>(context, listen: false);
    final success = await provider.updateStatus(requestId, status);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request ${status}!'),
          backgroundColor: AppColors.success,
        ),
      );
      _reload();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatTime(dynamic timestamp) {
    try {
      final dt = (timestamp as dynamic).toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}