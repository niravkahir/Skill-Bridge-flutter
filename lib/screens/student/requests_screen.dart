import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../widgets/profile/profile_picture.dart';

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
          // ✅ FIXED — visible colors on light background
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

    final bool showSender = mode == 'incoming' || mode == 'history';
    final name = showSender ? r['sender_name'] : r['receiver_name'];
    final image = showSender ? r['sender_image'] : r['receiver_image'];
    final college = showSender ? r['sender_college'] : r['receiver_college'];
    final semester =
    showSender ? r['sender_semester'] : r['receiver_semester'];

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
            // Header
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

            // Skill
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

            // Message
            Text(
              r['message'] ?? '',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),

            // Preferred time
            if ((r['preferred_time'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
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

            // Actions
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