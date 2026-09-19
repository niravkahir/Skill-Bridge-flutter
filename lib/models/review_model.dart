import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String reviewerId;
  final String reviewedUserId;
  final String meetingId;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.reviewedUserId,
    required this.meetingId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return ReviewModel(
      id: id,
      reviewerId: data['reviewer_id'] ?? '',
      reviewedUserId: data['reviewed_user_id'] ?? '',
      meetingId: data['meeting_id'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reviewer_id': reviewerId,
      'reviewed_user_id': reviewedUserId,
      'meeting_id': meetingId,
      'rating': rating,
      'comment': comment,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}