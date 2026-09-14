import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class ProfilePicture extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final bool showEditIcon;
  final VoidCallback? onEditTap;

  const ProfilePicture({
    super.key,
    this.imageUrl,
    this.size = 100,
    this.showEditIcon = false,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
            border: Border.all(color: AppColors.primary, width: 3),
          ),
          child: ClipOval(
            child: hasImage
                ? Image.network(
              // ✅ Key changes when URL changes → forces fresh load
              key: ValueKey(imageUrl),
              imageUrl!,
              fit: BoxFit.cover,
              width: size,
              height: size,
              errorBuilder: (context, error, stackTrace) {
                print('❌ Image load error: $error');
                return Icon(
                  Icons.person,
                  size: size * 0.6,
                  color: AppColors.primary,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: SizedBox(
                    width: size * 0.3,
                    height: size * 0.3,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            )
                : Icon(
              Icons.person,
              size: size * 0.6,
              color: AppColors.primary,
            ),
          ),
        ),
        if (showEditIcon)
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: onEditTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
      ],
    );
  }
}