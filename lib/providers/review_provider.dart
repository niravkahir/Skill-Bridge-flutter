import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';

class ReviewProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Map<String, dynamic>> _reviewsForUser = [];
  List<Map<String, dynamic>> _reviewsWrittenByUser = [];
  List<Map<String, dynamic>> _teachingReviews = [];
  List<Map<String, dynamic>> _learningReviews = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get reviewsForUser => _reviewsForUser;
  List<Map<String, dynamic>> get reviewsWrittenByUser =>
      _reviewsWrittenByUser;
  List<Map<String, dynamic>> get teachingReviews => _teachingReviews;
  List<Map<String, dynamic>> get learningReviews => _learningReviews;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ==================== LOAD ====================

  Future<void> loadReviewsForUser(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _reviewsForUser = await _firestore.getReviewsForUser(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAllReviewsSplit(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      final results = await Future.wait([
        _firestore.getTeachingReviews(userId),
        _firestore.getLearningReviews(userId),
      ]);
      _teachingReviews = results[0];
      _learningReviews = results[1];
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReviewsWrittenByUser(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _reviewsWrittenByUser =
      await _firestore.getReviewsWrittenByUser(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ==================== CHECK ====================

  Future<bool> hasReviewed({
    required String reviewerId,
    required String meetingId,
  }) async {
    return _firestore.hasReviewedMeeting(
      reviewerId: reviewerId,
      meetingId: meetingId,
    );
  }

  // ==================== SUBMIT ====================

  Future<bool> submitReview({
    required String reviewerId,
    required String reviewedUserId,
    required String meetingId,
    required int rating,
    required String comment,
  }) async {
    try {
      final already = await hasReviewed(
        reviewerId: reviewerId,
        meetingId: meetingId,
      );
      if (already) {
        _error = 'You already reviewed this meeting';
        return false;
      }

      final review = ReviewModel(
        id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
        reviewerId: reviewerId,
        reviewedUserId: reviewedUserId,
        meetingId: meetingId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _firestore.addReview(review);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void clearError() {
    _error = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}