import 'package:flutter/material.dart';

import '../ui/theme/app_colors.dart';
import '../ui/theme/app_text_styles.dart';

class XPFloatingText {
  static void show(BuildContext context, {required int amount, Offset? position}) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    // Default to center if no position provided
    final showPosition = position ?? Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );

    overlayEntry = OverlayEntry(
      builder: (context) => _XPFloatingWidget(
        amount: amount,
        position: showPosition,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _XPFloatingWidget extends StatefulWidget {
  final int amount;
  final Offset position;
  final VoidCallback onDismiss;

  const _XPFloatingWidget({
    required this.amount,
    required this.position,
    required this.onDismiss,
  });

  @override
  State<_XPFloatingWidget> createState() => _XPFloatingWidgetState();
}

class _XPFloatingWidgetState extends State<_XPFloatingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 1.0, curve: Curves.easeOut),
      ),
    );

    _moveAnimation = Tween<double>(begin: 0.0, end: -46.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.position.dx - 50, // Center roughly
      top: widget.position.dy,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _moveAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _moveAnimation.value),
              child: child,
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 100,
              alignment: Alignment.center,
              child: Text(
                "+${widget.amount} XP",
                style: AppTextStyles.headerMedium.copyWith(
                  fontSize: 20,
                  color: AppColors.primaryBlue,
                  shadows: [
                    Shadow(
                      color: AppColors.primaryBlue.withOpacity(0.75),
                      blurRadius: 14,
                    ),
                    Shadow(
                      color: AppColors.primaryViolet.withOpacity(0.35),
                      blurRadius: 18,
                    ),
                    const Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
