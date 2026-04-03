import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SecondaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final bool dangerOutline;

  const SecondaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.dangerOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final borderColor = enabled
        ? (dangerOutline ? AppColors.textDisabled : AppColors.borderSoft)
        : AppColors.borderSoft;
    final backgroundColor = enabled
        ? (dangerOutline ? Colors.transparent : AppColors.surface)
        : AppColors.surface;
    final textColor = enabled
        ? (dangerOutline ? AppColors.textDisabled : AppColors.textSecondary)
        : AppColors.textDisabled;

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
              color: borderColor,
              width: 1.0,
            ),
            color: backgroundColor,
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.button.copyWith(
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

