import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/review_provider.dart';
import '../../widgets/profile/profile_picture.dart';

class ReviewsListScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final bool showAsOwner;

  const ReviewsListScreen({
    super.key,
    required this.userId,
    required this.userName,
    this.showAsOwner = false,
  });

  @override
  State<ReviewsListScreen> createState() => _ReviewsListScreenState();
}

class _ReviewsListScreenState extends State<ReviewsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReviewProvider>(context, listen: false)
          .loadAllReviewsSplit(widget.userId);
    });
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
        title: Text(widget.showAsOwner
            ? 'My Reviews'
            : 'Reviews for ${widget.userName}'),
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
            Tab(text: 'As Teacher'),
            Tab(text: 'As Learner'),
          ],
        ),
      ),
      body: Consumer<ReviewProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent(
                provider.teachingReviews,
                emptyMessage: 'No teaching reviews yet',
                emptySubMessage:
                'Complete a session as a teacher to get reviews',
                bannerIcon: Icons.school,
              ),
              _buildTabContent(
                provider.learningReviews,
                emptyMessage: 'No learning reviews yet',
                emptySubMessage:
                'Complete a session as a learner to get reviews',
                bannerIcon: Icons.book,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabContent(
      List<Map<String, dynamic>> reviews, {
        required String emptyMessage,
        required String emptySubMessage,
        required IconData bannerIcon,
      }) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_border,
                size: 80, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                emptySubMessage,
                style: TextStyle(
                  color: AppColors.textHint,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Average for this tab
    final avg = reviews.fold<double>(
      0,
          (sum, r) => sum + ((r['rating'] ?? 0) as int),
    ) /
        reviews.length;

    return Column(
      children: [
        // Header summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(bannerIcon, color: Colors.white, size: 30),
              const SizedBox(height: 6),
              Text(
                avg.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < avg.round();
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 24,
                  );
                }),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on ${reviews.length} ${reviews.length == 1 ? "review" : "reviews"}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Reviews list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: reviews.length,
            itemBuilder: (context, i) => _reviewCard(reviews[i]),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(Map<String, dynamic> r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfilePicture(imageUrl: r['reviewer_image'], size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r['reviewer_name'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        r['reviewer_college'] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < (r['rating'] ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              r['comment'] ?? '',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatDate(r['created_at']),
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      final dt = (timestamp as dynamic).toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 30) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}