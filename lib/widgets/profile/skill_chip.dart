import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class SkillChip extends StatelessWidget {
  final String skillName;
  final String level;
  final VoidCallback? onRemove;

  const SkillChip({
    super.key,
    required this.skillName,
    required this.level,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    Color levelColor;
    switch (level.toLowerCase()) {
      case 'expert':
        levelColor = Colors.green;
        break;
      case 'intermediate':
        levelColor = Colors.orange;
        break;
      default:
        levelColor = Colors.blue;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: levelColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            skillName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($level)',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}