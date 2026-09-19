import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../models/user_skill_model.dart';
import '../models/learning_request_model.dart';
import '../models/meeting_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== USER OPERATIONS ====================

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

  // ==================== PROFILE OPERATIONS ====================

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

  // ==================== SKILL OPERATIONS ====================

  Future<List<Map<String, dynamic>>> getAllSkills() async {
    try {
      final snapshot = await _firestore
          .collection('skills')
          .where('status', isEqualTo: 'active')
          .get();

      final docs = snapshot.docs.toList();
      docs.sort((a, b) => (a.data()['name'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b.data()['name'] ?? '').toString().toLowerCase()));

      return docs
          .map((doc) => {
        'id': doc.id,
        ...doc.data(),
      })
          .toList();
    } catch (e) {
      throw Exception('Failed to get skills: $e');
    }
  }

  Future<List<UserSkillModel>> getUserSkills(String userId,
      {String? type}) async {
    try {
      Query query = _firestore
          .collection('user_skills')
          .where('user_id', isEqualTo: userId);

      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserSkillModel.fromFirestore(
          doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user skills: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getUserSkillsWithDetails(
      String userId) async {
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

  // ==================== STUDENT DISCOVERY ====================

  Future<List<Map<String, dynamic>>> getAllStudents(
      String currentUserId) async {
    try {
      final snapshot = await _firestore.collection('profiles').get();

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
      final profileDoc =
      await _firestore.collection('profiles').doc(userId).get();

      if (!profileDoc.exists) return null;

      final profileData = profileDoc.data()!;
      final userDoc =
      await _firestore.collection('users').doc(userId).get();

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
        'verification_status':
        profileData['verification_status'] ?? 'pending',
        'email': email,
      };
    } catch (e) {
      throw Exception('Failed to get student profile: $e');
    }
  }

  // ==================== SEARCH BY SKILL ====================

  Future<List<Map<String, dynamic>>> searchStudentsBySkill({
    required String skillId,
    required String currentUserId,
  }) async {
    try {
      final skillDocs = await _firestore
          .collection('user_skills')
          .where('skill_id', isEqualTo: skillId)
          .where('type', isEqualTo: 'teach')
          .get();

      if (skillDocs.docs.isEmpty) return [];

      final userIds = skillDocs.docs
          .map((d) => d.data()['user_id'] as String)
          .where((id) => id != currentUserId)
          .toSet()
          .take(10)
          .toList();

      if (userIds.isEmpty) return [];

      final profileDocs = await _firestore
          .collection('profiles')
          .where('user_id', whereIn: userIds)
          .get();

      final userDocs = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: userIds)
          .get();

      final emailMap = <String, String>{};
      for (var d in userDocs.docs) {
        emailMap[d.id] = (d.data()['email'] ?? '') as String;
      }

      return profileDocs.docs.map((d) {
        final data = d.data();
        return {
          'profile_id': d.id,
          'user_id': data['user_id'] ?? '',
          'full_name': data['full_name'] ?? 'Unknown',
          'college': data['college'] ?? '',
          'semester': data['semester'] ?? 1,
          'bio': data['bio'] ?? '',
          'profile_image': data['profile_image'] ?? '',
          'verification_status': data['verification_status'] ?? 'pending',
          'email': emailMap[data['user_id']] ?? '',
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to search by skill: $e');
    }
  }

  // ==================== ADMIN SKILL MANAGEMENT ====================

  Future<void> addSkill({
    required String name,
    required String category,
  }) async {
    try {
      await _firestore.collection('skills').add({
        'name': name,
        'category': category,
        'status': 'active',
        'created_at': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to add skill: $e');
    }
  }

  Future<void> updateSkill({
    required String skillId,
    required String name,
    required String category,
    required String status,
  }) async {
    try {
      await _firestore.collection('skills').doc(skillId).update({
        'name': name,
        'category': category,
        'status': status,
      });
    } catch (e) {
      throw Exception('Failed to update skill: $e');
    }
  }

  Future<void> deleteSkill(String skillId) async {
    try {
      await _firestore.collection('skills').doc(skillId).delete();
    } catch (e) {
      throw Exception('Failed to delete skill: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getAllSkillsForAdmin() async {
    try {
      final snapshot = await _firestore.collection('skills').get();

      final docs = snapshot.docs.toList();
      docs.sort((a, b) => (a.data()['name'] ?? '')
          .toString()
          .toLowerCase()
          .compareTo((b.data()['name'] ?? '').toString().toLowerCase()));

      return docs
          .map((doc) => {
        'id': doc.id,
        ...doc.data(),
      })
          .toList();
    } catch (e) {
      throw Exception('Failed to get skills: $e');
    }
  }

  // ==================== USER STATS ====================

  Future<double> getAverageRating(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('reviewed_user_id', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return 0.0;

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['rating'] ?? 0) as int;
      }
      return total / snapshot.docs.length;
    } catch (e) {
      return 0.0;
    }
  }

  Future<int> getReviewCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('reviews')
          .where('reviewed_user_id', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getTaughtCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('meetings')
          .where('teacher_id', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getLearnedCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('meetings')
          .where('learner_id', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getIncomingRequestsCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('learning_requests')
          .where('receiver_id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final reviewsSnap = await _firestore
          .collection('reviews')
          .where('reviewed_user_id', isEqualTo: userId)
          .get();

      double avgRating = 0.0;
      if (reviewsSnap.docs.isNotEmpty) {
        double total = 0;
        for (var doc in reviewsSnap.docs) {
          total += (doc.data()['rating'] ?? 0) as int;
        }
        avgRating = total / reviewsSnap.docs.length;
      }

      final taughtSnap = await _firestore
          .collection('meetings')
          .where('teacher_id', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final learnedSnap = await _firestore
          .collection('meetings')
          .where('learner_id', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      return {
        'average_rating': avgRating,
        'review_count': reviewsSnap.docs.length,
        'taught_count': taughtSnap.docs.length,
        'learned_count': learnedSnap.docs.length,
      };
    } catch (e) {
      print('❌ getUserStats error: $e');
      return {
        'average_rating': 0.0,
        'review_count': 0,
        'taught_count': 0,
        'learned_count': 0,
      };
    }
  }

  // ==================== LEARNING REQUESTS ====================

  Future<void> sendLearningRequest(LearningRequestModel request) async {
    try {
      await _firestore
          .collection('learning_requests')
          .doc(request.id)
          .set(request.toFirestore());
    } catch (e) {
      throw Exception('Failed to send request: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getIncomingRequests(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection('learning_requests')
          .where('receiver_id', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();

      final List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['sender_id'] as String? ?? '';
        final skillId = data['skill_id'] as String? ?? '';

        final senderProfile =
        await _firestore.collection('profiles').doc(senderId).get();
        final skillDoc =
        await _firestore.collection('skills').doc(skillId).get();

        results.add({
          'id': doc.id,
          'sender_id': senderId,
          'receiver_id': data['receiver_id'],
          'skill_id': skillId,
          'skill_name': skillDoc.data()?['name'] ?? 'Unknown Skill',
          'message': data['message'] ?? '',
          'preferred_time': data['preferred_time'] ?? '',
          'status': data['status'] ?? 'pending',
          'created_at': data['created_at'],
          'sender_name': senderProfile.data()?['full_name'] ?? 'Unknown',
          'sender_college': senderProfile.data()?['college'] ?? '',
          'sender_semester': senderProfile.data()?['semester'] ?? 1,
          'sender_image': senderProfile.data()?['profile_image'] ?? '',
        });
      }

      results.sort((a, b) {
        final aTime = (a['created_at'] as Timestamp).millisecondsSinceEpoch;
        final bTime = (b['created_at'] as Timestamp).millisecondsSinceEpoch;
        return bTime.compareTo(aTime);
      });

      return results;
    } catch (e) {
      throw Exception('Failed to load incoming requests: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getSentRequests(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('learning_requests')
          .where('sender_id', isEqualTo: userId)
          .get();

      final List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final receiverId = data['receiver_id'] as String? ?? '';
        final skillId = data['skill_id'] as String? ?? '';

        final receiverProfile =
        await _firestore.collection('profiles').doc(receiverId).get();
        final skillDoc =
        await _firestore.collection('skills').doc(skillId).get();

        results.add({
          'id': doc.id,
          'sender_id': data['sender_id'],
          'receiver_id': receiverId,
          'skill_id': skillId,
          'skill_name': skillDoc.data()?['name'] ?? 'Unknown Skill',
          'message': data['message'] ?? '',
          'preferred_time': data['preferred_time'] ?? '',
          'status': data['status'] ?? 'pending',
          'created_at': data['created_at'],
          'receiver_name': receiverProfile.data()?['full_name'] ?? 'Unknown',
          'receiver_college': receiverProfile.data()?['college'] ?? '',
          'receiver_semester': receiverProfile.data()?['semester'] ?? 1,
          'receiver_image': receiverProfile.data()?['profile_image'] ?? '',
        });
      }

      results.sort((a, b) {
        final aTime = (a['created_at'] as Timestamp).millisecondsSinceEpoch;
        final bTime = (b['created_at'] as Timestamp).millisecondsSinceEpoch;
        return bTime.compareTo(aTime);
      });

      return results;
    } catch (e) {
      throw Exception('Failed to load sent requests: $e');
    }
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required String status,
  }) async {
    try {
      await _firestore
          .collection('learning_requests')
          .doc(requestId)
          .update({
        'status': status,
        'responded_at': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to update request: $e');
    }
  }

  Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore
          .collection('learning_requests')
          .doc(requestId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete request: $e');
    }
  }

  /// Get request history (accepted + rejected incoming requests)
  Future<List<Map<String, dynamic>>> getRequestHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('learning_requests')
          .where('receiver_id', isEqualTo: userId)
          .get();

      final List<Map<String, dynamic>> results = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';

        if (status == 'pending') continue;

        final senderId = data['sender_id'] as String? ?? '';
        final skillId = data['skill_id'] as String? ?? '';

        final senderProfile =
        await _firestore.collection('profiles').doc(senderId).get();
        final skillDoc =
        await _firestore.collection('skills').doc(skillId).get();

        results.add({
          'id': doc.id,
          'sender_id': senderId,
          'receiver_id': data['receiver_id'],
          'skill_id': skillId,
          'skill_name': skillDoc.data()?['name'] ?? 'Unknown Skill',
          'message': data['message'] ?? '',
          'preferred_time': data['preferred_time'] ?? '',
          'status': status,
          'created_at': data['created_at'],
          'responded_at': data['responded_at'],
          'sender_name': senderProfile.data()?['full_name'] ?? 'Unknown',
          'sender_college': senderProfile.data()?['college'] ?? '',
          'sender_semester': senderProfile.data()?['semester'] ?? 1,
          'sender_image': senderProfile.data()?['profile_image'] ?? '',
        });
      }

      results.sort((a, b) {
        final aTime = a['responded_at'] != null
            ? (a['responded_at'] as Timestamp).millisecondsSinceEpoch
            : 0;
        final bTime = b['responded_at'] != null
            ? (b['responded_at'] as Timestamp).millisecondsSinceEpoch
            : 0;
        return bTime.compareTo(aTime);
      });

      return results;
    } catch (e) {
      throw Exception('Failed to load request history: $e');
    }
  }

  // ==================== MEETINGS ====================

  /// Create a new meeting
  Future<void> createMeeting(MeetingModel meeting) async {
    try {
      await _firestore
          .collection('meetings')
          .doc(meeting.id)
          .set(meeting.toFirestore());
    } catch (e) {
      throw Exception('Failed to create meeting: $e');
    }
  }

  /// Get upcoming meetings for a user (either teacher or learner)
  Future<List<Map<String, dynamic>>> getUpcomingMeetings(
      String userId) async {
    try {
      // As teacher
      final asTeacher = await _firestore
          .collection('meetings')
          .where('teacher_id', isEqualTo: userId)
          .where('status', isEqualTo: 'scheduled')
          .get();

      // As learner
      final asLearner = await _firestore
          .collection('meetings')
          .where('learner_id', isEqualTo: userId)
          .where('status', isEqualTo: 'scheduled')
          .get();

      final allDocs = [...asTeacher.docs, ...asLearner.docs];

      // Deduplicate by id
      final seenIds = <String>{};
      final results = <Map<String, dynamic>>[];

      for (var doc in allDocs) {
        if (seenIds.contains(doc.id)) continue;
        seenIds.add(doc.id);

        final data = doc.data();
        final isTeacher = data['teacher_id'] == userId;
        final otherId =
        isTeacher ? data['learner_id'] : data['teacher_id'];

        // Get other user's info
        final otherProfile =
        await _firestore.collection('profiles').doc(otherId).get();

        results.add({
          'id': doc.id,
          'request_id': data['request_id'] ?? '',
          'teacher_id': data['teacher_id'] ?? '',
          'learner_id': data['learner_id'] ?? '',
          'skill_id': data['skill_id'] ?? '',
          'skill_name': data['skill_name'] ?? 'Unknown Skill',
          'meeting_date': data['meeting_date'],
          'start_time': data['start_time'] ?? '',
          'end_time': data['end_time'] ?? '',
          'zoom_meeting_id': data['zoom_meeting_id'] ?? '',
          'zoom_join_url': data['zoom_join_url'] ?? '',
          'zoom_start_url': data['zoom_start_url'] ?? '',
          'status': data['status'] ?? 'scheduled',
          'topic': data['topic'] ?? '',
          'created_at': data['created_at'],
          'is_teacher': isTeacher,
          'other_user_id': otherId,
          'other_user_name':
          otherProfile.data()?['full_name'] ?? 'Unknown',
          'other_user_image':
          otherProfile.data()?['profile_image'] ?? '',
          'other_user_college':
          otherProfile.data()?['college'] ?? '',
          'other_user_semester':
          otherProfile.data()?['semester'] ?? 1,
        });
      }

      // Sort by date+time (earliest first)
      results.sort((a, b) {
        final aDate =
            (a['meeting_date'] as Timestamp).millisecondsSinceEpoch;
        final bDate =
            (b['meeting_date'] as Timestamp).millisecondsSinceEpoch;
        return aDate.compareTo(bDate);
      });

      return results;
    } catch (e) {
      throw Exception('Failed to load upcoming meetings: $e');
    }
  }

  /// Get completed meetings for a user
  Future<List<Map<String, dynamic>>> getCompletedMeetings(
      String userId) async {
    try {
      final asTeacher = await _firestore
          .collection('meetings')
          .where('teacher_id', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final asLearner = await _firestore
          .collection('meetings')
          .where('learner_id', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      final allDocs = [...asTeacher.docs, ...asLearner.docs];
      final seenIds = <String>{};
      final results = <Map<String, dynamic>>[];

      for (var doc in allDocs) {
        if (seenIds.contains(doc.id)) continue;
        seenIds.add(doc.id);

        final data = doc.data();
        final isTeacher = data['teacher_id'] == userId;
        final otherId =
        isTeacher ? data['learner_id'] : data['teacher_id'];

        final otherProfile =
        await _firestore.collection('profiles').doc(otherId).get();

        results.add({
          'id': doc.id,
          'request_id': data['request_id'] ?? '',
          'teacher_id': data['teacher_id'] ?? '',
          'learner_id': data['learner_id'] ?? '',
          'skill_id': data['skill_id'] ?? '',
          'skill_name': data['skill_name'] ?? 'Unknown Skill',
          'meeting_date': data['meeting_date'],
          'start_time': data['start_time'] ?? '',
          'end_time': data['end_time'] ?? '',
          'zoom_meeting_id': data['zoom_meeting_id'] ?? '',
          'zoom_join_url': data['zoom_join_url'] ?? '',
          'zoom_start_url': data['zoom_start_url'] ?? '',
          'status': data['status'] ?? 'completed',
          'topic': data['topic'] ?? '',
          'created_at': data['created_at'],
          'completed_at': data['completed_at'],
          'is_teacher': isTeacher,
          'other_user_id': otherId,
          'other_user_name':
          otherProfile.data()?['full_name'] ?? 'Unknown',
          'other_user_image':
          otherProfile.data()?['profile_image'] ?? '',
          'other_user_college':
          otherProfile.data()?['college'] ?? '',
          'other_user_semester':
          otherProfile.data()?['semester'] ?? 1,
        });
      }

      // Sort by completed date (latest first)
      results.sort((a, b) {
        final aTime = a['completed_at'] != null
            ? (a['completed_at'] as Timestamp).millisecondsSinceEpoch
            : 0;
        final bTime = b['completed_at'] != null
            ? (b['completed_at'] as Timestamp).millisecondsSinceEpoch
            : 0;
        return bTime.compareTo(aTime);
      });

      return results;
    } catch (e) {
      throw Exception('Failed to load completed meetings: $e');
    }
  }

  /// Get cancelled meetings for a user
  Future<List<Map<String, dynamic>>> getCancelledMeetings(
      String userId) async {
    try {
      final asTeacher = await _firestore
          .collection('meetings')
          .where('teacher_id', isEqualTo: userId)
          .where('status', isEqualTo: 'cancelled')
          .get();

      final asLearner = await _firestore
          .collection('meetings')
          .where('learner_id', isEqualTo: userId)
          .where('status', isEqualTo: 'cancelled')
          .get();

      final allDocs = [...asTeacher.docs, ...asLearner.docs];
      final seenIds = <String>{};
      final results = <Map<String, dynamic>>[];

      for (var doc in allDocs) {
        if (seenIds.contains(doc.id)) continue;
        seenIds.add(doc.id);

        final data = doc.data();
        final isTeacher = data['teacher_id'] == userId;
        final otherId =
        isTeacher ? data['learner_id'] : data['teacher_id'];

        final otherProfile =
        await _firestore.collection('profiles').doc(otherId).get();

        results.add({
          'id': doc.id,
          'request_id': data['request_id'] ?? '',
          'teacher_id': data['teacher_id'] ?? '',
          'learner_id': data['learner_id'] ?? '',
          'skill_id': data['skill_id'] ?? '',
          'skill_name': data['skill_name'] ?? 'Unknown Skill',
          'meeting_date': data['meeting_date'],
          'start_time': data['start_time'] ?? '',
          'end_time': data['end_time'] ?? '',
          'zoom_meeting_id': data['zoom_meeting_id'] ?? '',
          'zoom_join_url': data['zoom_join_url'] ?? '',
          'zoom_start_url': data['zoom_start_url'] ?? '',
          'status': data['status'] ?? 'cancelled',
          'topic': data['topic'] ?? '',
          'created_at': data['created_at'],
          'cancelled_at': data['cancelled_at'],
          'is_teacher': isTeacher,
          'other_user_id': otherId,
          'other_user_name':
          otherProfile.data()?['full_name'] ?? 'Unknown',
          'other_user_image':
          otherProfile.data()?['profile_image'] ?? '',
          'other_user_college':
          otherProfile.data()?['college'] ?? '',
          'other_user_semester':
          otherProfile.data()?['semester'] ?? 1,
        });
      }

      results.sort((a, b) {
        final aTime = a['cancelled_at'] != null
            ? (a['cancelled_at'] as Timestamp).millisecondsSinceEpoch
            : 0;
        final bTime = b['cancelled_at'] != null
            ? (b['cancelled_at'] as Timestamp).millisecondsSinceEpoch
            : 0;
        return bTime.compareTo(aTime);
      });

      return results;
    } catch (e) {
      throw Exception('Failed to load cancelled meetings: $e');
    }
  }

  /// Update meeting status (cancel / complete)
  Future<void> updateMeetingStatus({
    required String meetingId,
    required String status,
  }) async {
    try {
      final updates = <String, dynamic>{'status': status};

      if (status == 'completed') {
        updates['completed_at'] = Timestamp.now();
      } else if (status == 'cancelled') {
        updates['cancelled_at'] = Timestamp.now();
      }

      await _firestore
          .collection('meetings')
          .doc(meetingId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update meeting: $e');
    }
  }

  /// Get a single meeting by ID (full data)
  Future<Map<String, dynamic>?> getMeetingById(String meetingId) async {
    try {
      final doc =
      await _firestore.collection('meetings').doc(meetingId).get();
      if (!doc.exists) return null;

      final data = doc.data()!;
      final teacherProfile = await _firestore
          .collection('profiles')
          .doc(data['teacher_id'])
          .get();
      final learnerProfile = await _firestore
          .collection('profiles')
          .doc(data['learner_id'])
          .get();

      return {
        'id': doc.id,
        ...data,
        'teacher_name': teacherProfile.data()?['full_name'] ?? 'Unknown',
        'teacher_image': teacherProfile.data()?['profile_image'] ?? '',
        'teacher_college': teacherProfile.data()?['college'] ?? '',
        'teacher_semester': teacherProfile.data()?['semester'] ?? 1,
        'learner_name': learnerProfile.data()?['full_name'] ?? 'Unknown',
        'learner_image': learnerProfile.data()?['profile_image'] ?? '',
        'learner_college': learnerProfile.data()?['college'] ?? '',
        'learner_semester': learnerProfile.data()?['semester'] ?? 1,
      };
    } catch (e) {
      throw Exception('Failed to get meeting: $e');
    }
  }

  /// Find a meeting by its request ID (to check if one exists)
  Future<Map<String, dynamic>?> getMeetingByRequestId(
      String requestId) async {
    try {
      final snapshot = await _firestore
          .collection('meetings')
          .where('request_id', isEqualTo: requestId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data();

      return {
        'id': doc.id,
        ...data,
        'meeting_date_ts':
        (data['meeting_date'] as Timestamp).millisecondsSinceEpoch,
      };
    } catch (e) {
      print('⚠️ getMeetingByRequestId error: $e');
      return null;
    }
  }

}