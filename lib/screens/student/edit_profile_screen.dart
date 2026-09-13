import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/common/custom_button.dart';
import '../../widgets/common/custom_textfield.dart';
import '../../widgets/profile/profile_picture.dart';
import '../../utils/validators.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _collegeController = TextEditingController();
  final _semesterController = TextEditingController();
  final _bioController = TextEditingController();
  XFile? _selectedImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final profileProvider =
    Provider.of<ProfileProvider>(context, listen: false);
    final profile = profileProvider.profile;

    if (profile != null) {
      _nameController.text = profile.fullName;
      _collegeController.text = profile.college;
      _semesterController.text = profile.semester.toString();
      _bioController.text = profile.bio;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _collegeController.dispose();
    _semesterController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 500,
      maxHeight: 500,
      imageQuality: 80,
    );

    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider =
      Provider.of<ProfileProvider>(context, listen: false);
      final userId = authProvider.user!.id;

      // 1. Upload image FIRST if selected
      if (_selectedImage != null) {
        print('🚀 Uploading image...');

        final uploadSuccess = await profileProvider.uploadProfilePicture(
          userId,
          _selectedImage!,
        );

        if (!uploadSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Image upload failed: ${profileProvider.error ?? "Unknown error"}',
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 6),
              ),
            );
            setState(() => _isUploading = false);
          }
          return; // STOP
        }

        print('✅ Image uploaded and URL saved');
      } else {
        print('⚠️ No image selected — skipping upload');
      }

      // 2. Save profile text data
      final success = await profileProvider.saveProfile(
        userId: userId,
        fullName: _nameController.text.trim(),
        college: _collegeController.text.trim(),
        semester: int.parse(_semesterController.text.trim()),
        bio: _bioController.text.trim(),
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(profileProvider.error ?? 'Failed to save profile'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _isUploading
                ? null
                : () async {
              await _saveProfile();
            },
            child: Text(
              'Save',
              style: TextStyle(
                color: _isUploading ? AppColors.textHint : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Profile Picture
                  Center(
                    child: Column(
                      children: [
                        ProfilePicture(
                          imageUrl: _selectedImage != null
                              ? null
                              : profileProvider.profile?.profileImage,
                          size: 120,
                          showEditIcon: true,
                          onEditTap: _pickImage,
                        ),
                        if (_selectedImage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'New image selected',
                            style: TextStyle(
                              color: AppColors.success,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  CustomTextField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    validator: Validators.validateName,
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'College',
                    hint: 'Enter your college name',
                    controller: _collegeController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'College name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Semester',
                    hint: 'Enter your semester (1-8)',
                    controller: _semesterController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Semester is required';
                      }
                      final int? semester = int.tryParse(value);
                      if (semester == null || semester < 1 || semester > 8) {
                        return 'Enter a valid semester (1-8)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  CustomTextField(
                    label: 'Bio',
                    hint: 'Tell others about yourself',
                    controller: _bioController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bio is required';
                      }
                      if (value.length < 10) {
                        return 'Bio must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  CustomButton(
                    text: 'Save Profile',
                    onPressed: _isUploading
                        ? null
                        : () async {
                      await _saveProfile();
                    },
                    isLoading: _isUploading,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (_isUploading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Saving profile...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}