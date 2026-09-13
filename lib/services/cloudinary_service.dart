import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  /// Upload XFile (works on Web + Mobile + Desktop)
  Future<String> uploadProfileImage(String userId, XFile file) async {
    try {
      print('📤 Uploading to Cloudinary...');
      print('📤 Cloud: ${CloudinaryConfig.cloudName}');
      print('📤 Preset: ${CloudinaryConfig.uploadPreset}');

      final url = Uri.parse(CloudinaryConfig.uploadUrl);
      final request = http.MultipartRequest('POST', url);

      // Preset + folder + public_id
      request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;
      request.fields['folder'] = 'profile_images';
      request.fields['public_id'] = userId;
      //request.fields['overwrite'] = 'true';

      // ✅ Read as bytes — works on Web AND mobile
      final bytes = await file.readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: '$userId.jpg',
      );
      request.files.add(multipartFile);

      print('📤 Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📤 Status: ${response.statusCode}');
      print('📤 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final secureUrl = data['secure_url'] as String?;

        if (secureUrl == null) {
          throw Exception('No secure_url in response');
        }

        print('✅ Upload success: $secureUrl');
        return secureUrl;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'Upload failed (${response.statusCode}): ${error['error']?['message'] ?? response.body}');
      }
    } catch (e) {
      print('❌ Cloudinary upload error: $e');
      throw Exception('Failed to upload image: $e');
    }
  }
}