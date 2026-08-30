import 'package:cloud_firestore/cloud_firestore.dart';
class ProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String college;
  final int semester;
  final String bio;
  final String profileImage;
  final String verificationStatus;
  final String? email;
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
    this.email,
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
      email: data['email'],  // ✅ ADD THIS
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

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? college,
    int? semester,
    String? bio,
    String? profileImage,
    String? verificationStatus,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      college: college ?? this.college,
      semester: semester ?? this.semester,
      bio: bio ?? this.bio,
      profileImage: profileImage ?? this.profileImage,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}