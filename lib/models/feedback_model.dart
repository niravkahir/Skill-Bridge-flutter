import 'package:cloud_firestore/cloud_firestore.dart';
class FeedbackModel {
  final String id;
  final String meetingId;
  final String fromUserId;
  final String toUserId;
  final int rating;      // 1-5
  final String comment;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.meetingId,
    required this.fromUserId,
    required this.toUserId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory FeedbackModel.fromFirestore(Map<String, dynamic> data, String id) {
    return FeedbackModel(
      id: id,
      meetingId: data['meeting_id'] ?? '',
      fromUserId: data['from_user_id'] ?? '',
      toUserId: data['to_user_id'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meeting_id': meetingId,
      'from_user_id': fromUserId,
      'to_user_id': toUserId,
      'rating': rating,
      'comment': comment,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}