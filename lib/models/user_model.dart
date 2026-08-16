import 'package:cloud_firestore/cloud_firestore.dart';
class UserModel {
  final String id;
  final String email;
  final String password;  // Only used temporarily, not stored
  final String role;      // 'student' or 'admin'
  final String status;    // 'active' or 'deactivated'
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    this.password = '',
    this.role = 'student',
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Firestore document
  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      status: data['status'] ?? 'active',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      updatedAt: (data['updated_at'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'role': role,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with changes (for updates)
  UserModel copyWith({
    String? id,
    String? email,
    String? password,
    String? role,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}