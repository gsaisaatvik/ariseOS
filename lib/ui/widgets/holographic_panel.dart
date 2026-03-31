import 'package:flutter/material.dart';

import '../layout/responsive_layout.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Core container widget that approximates the Solo Leveling style panels.
class HolographicPanel extends StatelessWidget {
  final Widget? header;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final bool emphasize;

  const HolographicPanel({
    super.key,
    this.header,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return ContentConstrained(
      maxWidth: ResponsiveLayout.maxContentWidth(
        context,
        compactFactor: 0.92,
        mediumMax: 640,
        expandedMax: 700,
      ),
      child: Container(
        margin: margin,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surfaceElevated.withOpacity(0.96),
              AppColors.surface.withOpacity(0.94),
            ],
          ),
          border: Border.all(
            color: emphasize ? AppColors.borderStrong : AppColors.borderSoft,
            width: emphasize ? 1.6 : 1.0,
          ),
          boxShadow: [
            if (emphasize)
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.35),
                blurRadius: 22,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (header != null) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: DefaultTextStyle(
                  style: AppTextStyles.systemLabel,
                  child: header!,
                ),
              ),
              Container(
                height: 1,
                width: double.infinity,
                color: AppColors.borderSoft,
              ),
            ],
            Padding(
              padding: padding,
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

