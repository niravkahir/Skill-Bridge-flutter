import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Register
  Future<bool> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _user = await _authService.registerWithEmailPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      _user = await _authService.loginWithEmailPassword(
        email: email,
        password: password,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword({required String email}) async {
    _setLoading(true);
    _error = null;

    try {
      await _authService.resetPassword(email: email);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _authService.logout();
      _user = null;
    } catch (e) {
      _error = e.toString();
    }
  }

  // Clear error
  void clearError() {
    _error = null;
  }

  // Loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Check if user is logged in (call on app start)
  Future<void> checkAuthStatus() async {
    if (!_authService.isLoggedIn) {
      notifyListeners();
      return;
    }

    final userId = _authService.userId;
    if (userId == null) {
      notifyListeners();
      return;
    }

    try {
      // ✅ Check status from Firestore
      final FirestoreService firestoreService = FirestoreService();
      final user = await firestoreService.getUser(userId);

      if (user == null || user.status == 'deactivated') {
        // Deactivated → force logout
        await _authService.logout();
        _user = null;
        _error = 'Your account has been deactivated.';
        notifyListeners();
        return;
      }

      _user = user;
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }
}