import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  String? get userId => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  Future<UserModel> registerWithEmailPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed');
      }

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

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  Future<UserModel> loginWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Login failed');
      }

      final DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        await _auth.signOut();
        throw Exception('User data not found. Please contact support.');
      }

      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'active';

      if (status == 'deactivated') {
        await _auth.signOut();
        throw Exception(
          'Your account has been deactivated. Please contact admin.',
        );
      }

      return UserModel.fromFirestore(data, doc.id);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {

      if (e.toString().contains('deactivated')) {
        throw Exception(
          'Your account has been deactivated. Please contact admin.',
        );
      }
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please check or register.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check and try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in instead.';
      case 'invalid-email':
        return 'Please enter a valid email address (e.g., name@gmail.com).';
      case 'weak-password':
        return 'Password too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'operation-not-allowed':
        return 'This login method is not enabled. Contact support.';
      default:
        return 'Something went wrong. Please try again. (${e.code})';
    }
  }
}