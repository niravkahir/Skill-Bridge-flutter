import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadProfileImage(String userId, File imageFile) async {
    try {
      final ref = _storage
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<void> deleteProfileImage(String userId) async {
    try {
      final ref = _storage
          .ref()
          .child('profile_images')
          .child('$userId.jpg');

      await ref.delete();
    } catch (e) {
      if (e is FirebaseException && e.code == 'object-not-found') {
        return;
      }
      throw Exception('Failed to delete image: $e');
    }
  }

  Future<String> uploadVerificationDocument(String userId, File file) async {
    try {
      final ref = _storage
          .ref()
          .child('verification_documents')
          .child('${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }
}