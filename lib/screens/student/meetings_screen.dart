import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/meeting_provider.dart';
import '../../widgets/profile/profile_picture.dart';
import 'meeting_detail_screen.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final provider = Provider.of<MeetingProvider>(context, listen: false);
    provider.loadUpcomingMeetings(auth.user!.id);
    provider.loadCompletedMeetings(auth.user!.id);
    provider.loadCancelledMeetings(auth.user!.id);
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
          'My Meetings',
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
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: Consumer<MeetingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(provider.upcomingMeetings, 'upcoming'),
              _buildList(provider.completedMeetings, 'completed'),
              _buildList(provider.cancelledMeetings, 'cancelled'),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, String mode) {
    if (list.isEmpty) {
      IconData icon;
      String message;
      String sub;

      switch (mode) {
        case 'upcoming':
          icon = Icons.event_available;
          message = 'No upcoming meetings';
          sub = 'Schedule a meeting from an accepted request';
          break;
        case 'completed':
          icon = Icons.check_circle_outline;
          message = 'No completed meetings';
          sub = 'Your finished sessions will appear here';
          break;
        default:
          icon = Icons.cancel_outlined;
          message = 'No cancelled meetings';
          sub = 'Cancelled meetings will show here';
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(message,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 16)),
            const SizedBox(height: 6),
            Text(sub,
                style:
                TextStyle(color: AppColors.textHint, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (context, i) =>
            _meetingCard(list[i], mode: mode),
      ),
    );
  }

  Widget _meetingCard(Map<String, dynamic> m, {required String mode}) {
    final isTeacher = m['is_teacher'] == true;

    Color statusColor;
    switch (m['status']) {
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  MeetingDetailScreen(meetingId: m['id'], meetingData: m),
            ),
          ).then((_) => _reload());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  ProfilePicture(
                      imageUrl: m['other_user_image'], size: 48),
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
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                      Border.all(color: statusColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      (m['status'] as String).toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.textHint.withOpacity(0.2), height: 1),
              const SizedBox(height: 12),

              // Skill + role
              Row(
                children: [
                  const Icon(Icons.school,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    m['skill_name'] ?? 'Skill',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
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
                      isTeacher ? 'You teach' : 'You learn',
                      style: TextStyle(
                        fontSize: 11,
                        color: isTeacher ? Colors.blue : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Date + Time
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    '${_formatDate(m['meeting_date'])} • ${m['start_time']} - ${m['end_time']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      final dt = (timestamp as dynamic).toDate();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}