import 'package:cloud_firestore/cloud_firestore.dart';
class LearningRequestModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String skillId;
  final String message;
  final String status; // 'pending', 'accepted', 'rejected', 'cancelled'
  final DateTime createdAt;

  LearningRequestModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.skillId,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory LearningRequestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return LearningRequestModel(
      id: id,
      senderId: data['sender_id'] ?? '',
      receiverId: data['receiver_id'] ?? '',
      skillId: data['skill_id'] ?? '',
      message: data['message'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sender_id': senderId,
      'receiver_id': receiverId,
      'skill_id': skillId,
      'message': message,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}