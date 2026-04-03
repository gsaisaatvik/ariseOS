import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PrimaryActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final bool dangerTone;

  const PrimaryActionButton({
    super.key,
    required this.label,
    this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    this.dangerTone = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    const Color dangerRed1 = Color(0xFFFF3B3B);
    const Color dangerRed2 = Color(0xFF8A0F0F);
    final borderColor = enabled
        ? (dangerTone ? AppColors.danger : AppColors.borderStrong)
        : AppColors.borderSoft;

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
              width: 1.2,
            ),
            gradient: enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: dangerTone
                        ? const [dangerRed1, dangerRed2]
                        : const [
                            AppColors.primaryBlue,
                            AppColors.primaryViolet
                          ],
                  )
                : null,
            color: enabled ? null : AppColors.surface,
          ),
          alignment: Alignment.center,
          child: Text(
            label.toUpperCase(),
            style: AppTextStyles.button.copyWith(
              color: enabled
                  ? (dangerTone ? Colors.white : AppColors.background)
                  : AppColors.textDisabled,
            ),
          ),
        ),
      ),
    );
  }
}

