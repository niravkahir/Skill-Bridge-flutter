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
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(0.1),
            border: Border.all(
              color: AppColors.primary,
              width: 3,
            ),
            image: imageUrl != null && imageUrl!.isNotEmpty
                ? DecorationImage(
              image: NetworkImage(imageUrl!),
              fit: BoxFit.cover,
            )
                : null,
          ),
          child: imageUrl == null || imageUrl!.isEmpty
              ? Icon(
            Icons.person,
            size: size * 0.6,
            color: AppColors.primary,
          )
              : null,
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