import 'package:flutter/material.dart';
import 'dart:io';
import '../models/profile_model.dart';
import '../models/user_skill_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ProfileProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final StorageService _storage = StorageService();

  ProfileModel? _profile;
  List<UserSkillModel> _teachSkills = [];
  List<UserSkillModel> _learnSkills = [];
  List<Map<String, dynamic>> _teachSkillsWithDetails = [];
  List<Map<String, dynamic>> _learnSkillsWithDetails = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  ProfileModel? get profile => _profile;
  List<UserSkillModel> get teachSkills => _teachSkills;
  List<UserSkillModel> get learnSkills => _learnSkills;
  List<Map<String, dynamic>> get teachSkillsWithDetails => _teachSkillsWithDetails;
  List<Map<String, dynamic>> get learnSkillsWithDetails => _learnSkillsWithDetails;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get fullName => _profile?.fullName ?? 'Unknown';
  String get profileImage => _profile?.profileImage ?? '';
  bool get isVerified => _profile?.verificationStatus == 'verified';

  // Load profile data
  Future<void> loadProfile(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      // Load profile
      _profile = await _firestore.getProfile(userId);

      // Load skills with details
      _teachSkillsWithDetails = await _firestore.getUserSkillsWithDetails(userId)
          .then((skills) => skills.where((s) => s['type'] == 'teach').toList());

      _learnSkillsWithDetails = await _firestore.getUserSkillsWithDetails(userId)
          .then((skills) => skills.where((s) => s['type'] == 'learn').toList());

    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Create or update profile
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
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload profile picture
  Future<bool> uploadProfilePicture(String userId, File imageFile) async {
    _setLoading(true);
    _error = null;

    try {
      final imageUrl = await _storage.uploadProfileImage(userId, imageFile);
      await _firestore.updateProfilePicture(userId, imageUrl);

      if (_profile != null) {
        _profile = _profile!.copyWith(profileImage: imageUrl);
      }
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add skill
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

      // Reload skills
      await loadProfile(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Remove skill
  Future<bool> removeSkill(String skillId) async {
    try {
      await _firestore.removeUserSkill(skillId);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Remove all skills by type
  Future<bool> removeAllSkills(String userId, String type) async {
    try {
      await _firestore.removeUserSkillsByType(userId, type);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}