import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../models/user_skill_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  Future<ProfileModel?> getProfile(String userId) async {
    try {
      final doc = await _firestore.collection('profiles').doc(userId).get();
      if (doc.exists) {
        return ProfileModel.fromFirestore(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<Map<String, dynamic>?> getCurrentUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('profiles').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<void> saveProfile(ProfileModel profile) async {
    try {
      await _firestore
          .collection('profiles')
          .doc(profile.userId)
          .set(profile.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  Future<void> updateProfilePicture(String userId, String imageUrl) async {
    try {
      await _firestore.collection('profiles').doc(userId).update({
        'profile_image': imageUrl,
        'updated_at': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update profile picture: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllSkills() async {
    try {
      final snapshot = await _firestore
          .collection('skills')
          .where('status', isEqualTo: 'active')
          .orderBy('name')
          .get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get skills: $e');
    }
  }

  Future<List<UserSkillModel>> getUserSkills(String userId, {String? type}) async {
    try {
      Query query = _firestore
          .collection('user_skills')
          .where('user_id', isEqualTo: userId);

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) =>
          UserSkillModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      throw Exception('Failed to get user skills: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserSkillsWithDetails(String userId) async {
    try {
      final userSkills = await getUserSkills(userId);
      final List<Map<String, dynamic>> result = [];

      for (var userSkill in userSkills) {
        final skillDoc = await _firestore
            .collection('skills')
            .doc(userSkill.skillId)
            .get();

        if (skillDoc.exists) {
          final skillData = skillDoc.data()!;
          result.add({
            'id': userSkill.id,
            'skill_id': userSkill.skillId,
            'skill_name': skillData['name'] ?? 'Unknown',
            'skill_category': skillData['category'] ?? 'Uncategorized',
            'type': userSkill.type,
            'skill_level': userSkill.skillLevel.toString().split('.').last,
          });
        }
      }
      return result;
    } catch (e) {
      throw Exception('Failed to get user skills with details: $e');
    }
  }

  Future<void> addUserSkill(UserSkillModel userSkill) async {
    try {
      await _firestore
          .collection('user_skills')
          .doc(userSkill.id)
          .set(userSkill.toFirestore());
    } catch (e) {
      throw Exception('Failed to add skill: $e');
    }
  }

  Future<void> removeUserSkill(String id) async {
    try {
      await _firestore.collection('user_skills').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to remove skill: $e');
    }
  }

  Future<void> removeUserSkillsByType(String userId, String type) async {
    try {
      final snapshot = await _firestore
          .collection('user_skills')
          .where('user_id', isEqualTo: userId)
          .where('type', isEqualTo: type)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      throw Exception('Failed to remove skills: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllStudents(String currentUserId) async {
    try {
      final snapshot = await _firestore
          .collection('profiles')
          .get();

      final List<Map<String, dynamic>> students = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['user_id'] != currentUserId) {
          final userDoc = await _firestore
              .collection('users')
              .doc(data['user_id'])
              .get();

          String email = '';
          if (userDoc.exists) {
            final userData = userDoc.data();
            if (userData != null && userData['email'] != null) {
              email = userData['email'] as String;
            }
          }

          students.add({
            'profile_id': doc.id,
            'user_id': data['user_id'] ?? '',
            'full_name': data['full_name'] ?? 'Unknown',
            'college': data['college'] ?? '',
            'semester': data['semester'] ?? 1,
            'bio': data['bio'] ?? '',
            'profile_image': data['profile_image'] ?? '',
            'verification_status': data['verification_status'] ?? 'pending',
            'email': email,
          });
        }
      }
      return students;
    } catch (e) {
      throw Exception('Failed to get students: $e');
    }
  }

  Future<Map<String, dynamic>?> getStudentProfile(String userId) async {
    try {
      final profileDoc = await _firestore
          .collection('profiles')
          .doc(userId)
          .get();

      if (!profileDoc.exists) return null;

      final profileData = profileDoc.data()!;
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      String email = '';
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null && userData['email'] != null) {
          email = userData['email'] as String;
        }
      }

      return {
        'profile_id': profileDoc.id,
        'user_id': userId,
        'full_name': profileData['full_name'] ?? 'Unknown',
        'college': profileData['college'] ?? '',
        'semester': profileData['semester'] ?? 1,
        'bio': profileData['bio'] ?? '',
        'profile_image': profileData['profile_image'] ?? '',
        'verification_status': profileData['verification_status'] ?? 'pending',
        'email': email,
      };
    } catch (e) {
      throw Exception('Failed to get student profile: $e');
    }
  }
}