import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get user ID
  String? get userId => _auth.currentUser?.uid;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Register with email & password
  // Register with email & password
  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      print('📝 Starting registration for: $email');

      // 1. Create user in Firebase Auth
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('✅ Auth user created: ${userCredential.user?.uid}');

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed');
      }

      // 2. Save user data to Firestore
      final UserModel userModel = UserModel(
        id: user.uid,
        email: email,
        role: 'student',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(
        userModel.toFirestore(),
      );
      print('✅ User saved to Firestore');

      // 3. Create empty profile
      await _firestore.collection('profiles').doc(user.uid).set({
        'user_id': user.uid,
        'full_name': fullName,
        'college': '',
        'semester': 1,
        'bio': '',
        'profile_image': '',
        'verification_status': 'pending',
        'created_at': Timestamp.now(),
        'updated_at': Timestamp.now(),
      });
      print('✅ Profile created in Firestore');

      return userModel;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuthException: ${e.code} - ${e.message}');
      throw _handleAuthError(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Login with email & password
  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      // 1. Sign in to Firebase Auth
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Login failed');
      }

      // 2. Get user data from Firestore
      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        throw Exception('User data not found');
      }

      return UserModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  // Handle Firebase Auth Errors
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'Email already in use.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'An error occurred: ${e.message}';
    }
  }
}