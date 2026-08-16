import 'package:cloud_firestore/cloud_firestore.dart';
class VerificationRequestModel {
  final String id;
  final String userId;
  final String documentUrl;  // URL of uploaded student ID
  final String status;       // 'pending', 'approved', 'rejected'
  final String adminComment;
  final DateTime submittedAt;
  final DateTime? reviewedAt;

  VerificationRequestModel({
    required this.id,
    required this.userId,
    required this.documentUrl,
    required this.status,
    required this.adminComment,
    required this.submittedAt,
    this.reviewedAt,
  });

  factory VerificationRequestModel.fromFirestore(Map<String, dynamic> data, String id) {
    return VerificationRequestModel(
      id: id,
      userId: data['user_id'] ?? '',
      documentUrl: data['document_url'] ?? '',
      status: data['status'] ?? 'pending',
      adminComment: data['admin_comment'] ?? '',
      submittedAt: (data['submitted_at'] as Timestamp).toDate(),
      reviewedAt: data['reviewed_at'] != null
          ? (data['reviewed_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'document_url': documentUrl,
      'status': status,
      'admin_comment': adminComment,
      'submitted_at': Timestamp.fromDate(submittedAt),
      'reviewed_at': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }
}