import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../widgets/profile/profile_picture.dart';

class WriteReviewScreen extends StatefulWidget {
  final Map<String, dynamic> meetingData;

  const WriteReviewScreen({
    super.key,
    required this.meetingData,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      _showError('Please select a star rating');
      return;
    }

    if (_commentController.text.trim().length < 10) {
      _showError('Please write at least 10 characters');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final provider = Provider.of<ReviewProvider>(context, listen: false);

      final m = widget.meetingData;
      final reviewedUserId = m['other_user_id'];
      final meetingId = m['id'];

      // ✅ Null safety checks
      if (reviewedUserId == null || reviewedUserId.toString().isEmpty) {
        _showError('Cannot determine who to review. Please try again.');
        setState(() => _isSubmitting = false);
        return;
      }

      if (meetingId == null || meetingId.toString().isEmpty) {
        _showError('Meeting information is missing. Please try again.');
        setState(() => _isSubmitting = false);
        return;
      }

      final success = await provider.submitReview(
        reviewerId: auth.user!.id,
        reviewedUserId: reviewedUserId.toString(),
        meetingId: meetingId.toString(),
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted! Thank you 🎉'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, 'submitted');
      } else {
        _showError(provider.error ?? 'Failed to submit review');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
    final m = widget.meetingData;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Write a Review'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User preview
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rating
            const Text(
              'How was your experience?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a star to rate',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    onPressed: () =>
                        setState(() => _rating = starIndex),
                    iconSize: 48,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      starIndex <= _rating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                _ratingLabel(_rating),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _rating > 0
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Comment
            const Text(
              'Write your review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Share what you learned or how the session went (min 10 chars)',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              maxLines: 5,
              minLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText:
                'e.g., "Nirav explained Flutter state management clearly. Very helpful!"',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.send,
                    color: Colors.white, size: 20),
                label: Text(
                  _isSubmitting ? 'Submitting...' : 'Submit Review',
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor 😞';
      case 2:
        return 'Fair 😐';
      case 3:
        return 'Good 🙂';
      case 4:
        return 'Very Good 😊';
      case 5:
        return 'Excellent! 🤩';
      default:
        return 'Not rated yet';
    }
  }
}