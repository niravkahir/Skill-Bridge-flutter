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

  // Load all skills
  Future<void> loadSkills() async {
    _setLoading(true);
    _error = null;

    try {
      _allSkills = await _firestore.getAllSkills();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // Get skill by ID
  Map<String, dynamic>? getSkillById(String id) {
    try {
      return _allSkills.firstWhere((skill) => skill['id'] == id);
    } catch (e) {
      return null;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}