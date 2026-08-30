import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class VerificationBadge extends StatelessWidget {
  final String status; // 'pending', 'verified', 'rejected'

  const VerificationBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'verified':
        color = AppColors.success;
        label = 'Verified';
        icon = Icons.verified;
        break;
      case 'rejected':
        color = AppColors.error;
        label = 'Rejected';
        icon = Icons.cancel;
        break;
      default:
        color = AppColors.warning;
        label = 'Pending';
        icon = Icons.hourglass_empty;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}