import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Standard header used for NOTIFICATION / QUEST INFO style panels.
class SystemHeaderBar extends StatelessWidget {
  final String label;
  final IconData icon;

  const SystemHeaderBar({
    super.key,
    required this.label,
    this.icon = Icons.info_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.systemLabel.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        Icon(
          icon,
          size: 16,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

