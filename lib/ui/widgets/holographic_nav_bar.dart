import 'package:flutter/material.dart';

import '../layout/responsive_layout.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class HolographicNavItem {
  final IconData icon;
  final String label;

  const HolographicNavItem({
    required this.icon,
    required this.label,
  });
}

class HolographicNavBar extends StatelessWidget {
  final List<HolographicNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HolographicNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final maxWidth = ResponsiveLayout.maxContentWidth(
      context,
      compactFactor: 0.94,
      mediumMax: 520,
      expandedMax: 560,
    );

    return SafeArea(
      top: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.9),
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.borderSoft, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final bool selected = index == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: selected
                              ? AppColors.primaryBlue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          size: 20,
                          color: selected
                              ? AppColors.primaryBlue
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label.toUpperCase(),
                          style: AppTextStyles.systemLabel.copyWith(
                            fontSize: 9,
                            letterSpacing: 2,
                            color: selected
                                ? AppColors.primaryBlue
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

