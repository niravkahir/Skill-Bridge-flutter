import 'package:cloud_firestore/cloud_firestore.dart';
class ProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String college;
  final int semester;
  final String bio;
  final String profileImage;
  final String verificationStatus; // 'pending', 'verified', 'rejected'
  final DateTime createdAt;
  final DateTime updatedAt;

  ProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.college,
    required this.semester,
    required this.bio,
    required this.profileImage,
    required this.verificationStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ProfileModel(
      id: id,
      userId: data['user_id'] ?? '',
      fullName: data['full_name'] ?? '',
      college: data['college'] ?? '',
      semester: data['semester'] ?? 1,
      bio: data['bio'] ?? '',
      profileImage: data['profile_image'] ?? '',
      verificationStatus: data['verification_status'] ?? 'pending',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'college': college,
      'semester': semester,
      'bio': bio,
      'profile_image': profileImage,
      'verification_status': verificationStatus,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }
}