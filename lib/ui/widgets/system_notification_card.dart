import 'package:flutter/material.dart';
import 'dart:ui';

import 'system_header_bar.dart';

/// Unified visual language for every system-facing message.
enum SystemNotificationType {
  success,
  warning,
  danger,
  info,
}

class SystemNotificationCard extends StatefulWidget {
  const SystemNotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    this.playerName,
    this.messageWidget,
    this.actions,
    this.animate = true,
  });

  final String title;
  final String message;
  final SystemNotificationType type;
  final String? playerName;
  final Widget? messageWidget;
  final Widget? actions;
  final bool animate;

  @override
  State<SystemNotificationCard> createState() => _SystemNotificationCardState();
}

class _SystemNotificationCardState extends State<SystemNotificationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
    if (widget.animate) {
      _c.forward();
    } else {
      _c.value = 1.0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Color get _accent {
    switch (widget.type) {
      case SystemNotificationType.success:
        return const Color(0xFF00FFFF);
      case SystemNotificationType.warning:
        return const Color(0xFF00FFFF);
      case SystemNotificationType.danger:
        return const Color(0xFFFF2200);
      case SystemNotificationType.info:
        return const Color(0xFF00FFFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;
    
    return RepaintBoundary(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // 1. Frosted Glass Background
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000000).withValues(alpha: 0.95),
                      border: Border.all(
                        color: accent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.3),
                          blurRadius: 25.0,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        // Title Section
                        Text(
                          "[${widget.title.toUpperCase()}]",
                          style: TextStyle(
                            color: accent,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Message Section
                        if (widget.messageWidget != null)
                          widget.messageWidget!
                        else
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.5,
                            ),
                          ),
                        if (widget.actions != null) ...[
                          const SizedBox(height: 24),
                          widget.actions!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // 2. Floating Badge (Top Center)
          Positioned(
            top: -12,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000000),
                    border: Border.all(color: accent, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, color: accent, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        "QUEST INFO",
                        style: TextStyle(
                          color: accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
