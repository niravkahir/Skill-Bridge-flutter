import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/profile_model.dart';
import '../models/user_skill_model.dart';
import '../services/firestore_service.dart';
import '../services/cloudinary_service.dart';

class ProfileProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final CloudinaryService _cloudinary = CloudinaryService();

  ProfileModel? _profile;
  List<UserSkillModel> _teachSkills = [];
  List<UserSkillModel> _learnSkills = [];
  List<Map<String, dynamic>> _teachSkillsWithDetails = [];
  List<Map<String, dynamic>> _learnSkillsWithDetails = [];
  bool _isLoading = false;
  String? _error;

  // ==================== GETTERS ====================
  ProfileModel? get profile => _profile;
  List<UserSkillModel> get teachSkills => _teachSkills;
  List<UserSkillModel> get learnSkills => _learnSkills;
  List<Map<String, dynamic>> get teachSkillsWithDetails =>
      _teachSkillsWithDetails;
  List<Map<String, dynamic>> get learnSkillsWithDetails =>
      _learnSkillsWithDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get fullName => _profile?.fullName ?? 'Unknown';
  String get profileImage => _profile?.profileImage ?? '';
  bool get isVerified => _profile?.verificationStatus == 'verified';

  // ==================== LOAD PROFILE ====================
  Future<void> loadProfile(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      _profile = await _firestore.getProfile(userId);

      final allSkills = await _firestore.getUserSkillsWithDetails(userId);

      _teachSkillsWithDetails =
          allSkills.where((s) => s['type'] == 'teach').toList();
      _learnSkillsWithDetails =
          allSkills.where((s) => s['type'] == 'learn').toList();

      print('✅ Profile loaded. Teach: ${_teachSkillsWithDetails.length}, '
          'Learn: ${_learnSkillsWithDetails.length}');
    } catch (e) {
      _error = e.toString();
      print('❌ loadProfile error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== SAVE PROFILE ====================
  Future<bool> saveProfile({
    required String userId,
    required String fullName,
    required String college,
    required int semester,
    required String bio,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final profile = ProfileModel(
        id: userId,
        userId: userId,
        fullName: fullName,
        college: college,
        semester: semester,
        bio: bio,
        profileImage: _profile?.profileImage ?? '',
        verificationStatus: _profile?.verificationStatus ?? 'pending',
        createdAt: _profile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.saveProfile(profile);
      _profile = profile;
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ saveProfile error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== UPLOAD PROFILE PICTURE (CLOUDINARY) ====================
  Future<bool> uploadProfilePicture(String userId, XFile imageFile) async {
    _setLoading(true);
    _error = null;

    try {
      print('📸 Starting upload for user: $userId');

      // 1. Upload to Cloudinary
      final imageUrl = await _cloudinary.uploadProfileImage(userId, imageFile);
      print('✅ Cloudinary URL: $imageUrl');

      // 2. Save URL to Firestore
      await _firestore.updateProfilePicture(userId, imageUrl);
      print('✅ Firestore updated with image URL');

      // 3. Update local state
      if (_profile != null) {
        _profile = _profile!.copyWith(profileImage: imageUrl);
      }

      return true;
    } catch (e) {
      print('❌ Upload failed: $e');
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== ADD SKILL ====================
  Future<bool> addSkill({
    required String userId,
    required String skillId,
    required String type,
    required SkillLevel skillLevel,
  }) async {
    try {
      final userSkill = UserSkillModel(
        id: '${userId}_${skillId}_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        skillId: skillId,
        type: type,
        skillLevel: skillLevel,
      );

      await _firestore.addUserSkill(userSkill);
      await loadProfile(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ addSkill error: $e');
      return false;
    }
  }

  // ==================== REMOVE SKILL ====================
  Future<bool> removeSkill(String skillId) async {
    try {
      await _firestore.removeUserSkill(skillId);
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ removeSkill error: $e');
      return false;
    }
  }

  // ==================== REMOVE ALL SKILLS BY TYPE ====================
  Future<bool> removeAllSkills(String userId, String type) async {
    try {
      await _firestore.removeUserSkillsByType(userId, type);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ==================== CLEAR ERROR ====================
  void clearError() {
    _error = null;
  }

  // ==================== HELPER ====================
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}