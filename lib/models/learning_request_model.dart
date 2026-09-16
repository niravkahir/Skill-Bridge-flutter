import 'package:cloud_firestore/cloud_firestore.dart';

class LearningRequestModel {
  final String id;
  final String senderId;      // Student who wants to learn
  final String receiverId;    // Student who can teach
  final String skillId;       // Skill being requested
  final String message;       // Why they want to learn
  final String preferredTime; // e.g., "Weekends, evenings"
  final String status;        // pending | accepted | rejected | cancelled
  final DateTime createdAt;
  final DateTime? respondedAt;

  LearningRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.skillId,
    required this.message,
    required this.preferredTime,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory LearningRequestModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return LearningRequestModel(
      id: id,
      senderId: data['sender_id'] ?? '',
      receiverId: data['receiver_id'] ?? '',
      skillId: data['skill_id'] ?? '',
      message: data['message'] ?? '',
      preferredTime: data['preferred_time'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      respondedAt: data['responded_at'] != null
          ? (data['responded_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'skill_id': skillId,
      'message': message,
      'preferred_time': preferredTime,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'responded_at':
      respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
    };
  }
}