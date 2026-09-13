import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class SkillProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Map<String, dynamic>> _allSkills = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get allSkills => _allSkills;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load only ACTIVE skills (for normal users)
  Future<void> loadSkills() async {
    _setLoading(true);
    _error = null;
    try {
      _allSkills = await _firestore.getAllSkills();
      print('✅ Loaded ${_allSkills.length} skills');
      for (var s in _allSkills) {
        print('   → ${s['name']} (${s['status']})');
      }
    } catch (e) {
      _error = e.toString();
      print('❌ Skills error: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load ALL skills including inactive (for admin)
  Future<void> loadAllSkillsForAdmin() async {
    _setLoading(true);
    _error = null;
    try {
      _allSkills = await _firestore.getAllSkillsForAdmin();
      print('✅ Admin loaded ${_allSkills.length} skills');
    } catch (e) {
      _error = e.toString();
      print('❌ Admin skills error: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addSkill({
    required String name,
    required String category,
  }) async {
    try {
      await _firestore.addSkill(name: name, category: category);
      await loadAllSkillsForAdmin();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateSkill({
    required String skillId,
    required String name,
    required String category,
    required String status,
  }) async {
    try {
      await _firestore.updateSkill(
        skillId: skillId,
        name: name,
        category: category,
        status: status,
      );
      await loadAllSkillsForAdmin();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> deleteSkill(String skillId) async {
    try {
      await _firestore.deleteSkill(skillId);
      await loadAllSkillsForAdmin();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Map<String, dynamic>? getSkillById(String id) {
    try {
      return _allSkills.firstWhere((s) => s['id'] == id);
    } catch (_) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}