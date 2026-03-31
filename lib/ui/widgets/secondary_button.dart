import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;

  const SecondaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.zero,
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: enabled ? AppColors.borderSoft : AppColors.borderSoft,
              width: 1.0,
            ),
            color: AppColors.surface,
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.button.copyWith(
              color: enabled ? AppColors.textSecondary : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

