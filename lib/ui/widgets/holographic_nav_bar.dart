import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../layout/responsive_layout.dart';

const Color _kCyan = Color(0xFF00E5FF);
const Color _kBarBg = Color(0xFF0A0D1A);
const Color _kInactive = Color.fromRGBO(255, 255, 255, 0.35);

class HolographicNavItem {
  final IconData icon;
  final String label;

  const HolographicNavItem({
    required this.icon,
    required this.label,
  });
}

class HolographicNavBar extends StatefulWidget {
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
  State<HolographicNavBar> createState() => _HolographicNavBarState();
}

class _HolographicNavBarState extends State<HolographicNavBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _punchController;
  late Animation<double> _punchScale;
  int? _punchedIndex;

  @override
  void initState() {
    super.initState();
    _punchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _punchScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 80 / 320,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 240 / 320,
      ),
    ]).animate(_punchController);
  }

  @override
  void dispose() {
    _punchController.dispose();
    super.dispose();
  }

  void _onItemTap(int index) {
    HapticFeedback.heavyImpact();
    setState(() => _punchedIndex = index);
    _punchController.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _punchedIndex = null);
    });
    widget.onTap(index);
  }

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
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 1,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _kCyan.withValues(alpha: 0.45),
                      _kCyan.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
              Container(
                height: 64,
                padding: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
                decoration: const BoxDecoration(
                  color: _kBarBg,
                  border: Border(
                    top: BorderSide(
                      color: Color.fromRGBO(0, 229, 255, 0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(widget.items.length, (index) {
                    final item = widget.items[index];
                    final bool selected = index == widget.currentIndex;
                    final bool punching = index == _punchedIndex;

                    return Expanded(
                      child: Material(
                        color: Colors.transparent,
                        elevation: selected ? 8 : 0,
                        shadowColor: selected ? _kCyan : Colors.transparent,
                        child: InkWell(
                          onTap: () => _onItemTap(index),
                          child: AnimatedBuilder(
                            animation: _punchScale,
                            builder: (context, child) {
                              final scale = punching
                                  ? _punchScale.value
                                  : 1.0;
                              return Transform.scale(
                                scale: scale,
                                alignment: Alignment.center,
                                child: child,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    alignment: Alignment.topCenter,
                                    children: [
                                      if (selected)
                                        Positioned(
                                          top: -2,
                                          left: 8,
                                          right: 8,
                                          child: Container(
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: _kCyan.withValues(alpha: 0.85),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: _kCyan.withValues(alpha: 0.7),
                                                  blurRadius: 8,
                                                  spreadRadius: 0,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      Icon(
                                        item.icon,
                                        size: 22,
                                        color: selected ? _kCyan : _kInactive,
                                        shadows: selected
                                            ? [
                                                Shadow(
                                                  color: _kCyan.withValues(alpha: 0.9),
                                                  blurRadius: 8,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.5,
                                      color: selected ? _kCyan : _kInactive,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
