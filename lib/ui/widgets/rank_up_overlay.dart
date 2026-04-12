import 'package:flutter/material.dart';

import '../../system/rank_up_event.dart';
import '../../ui/theme/app_colors.dart';

// ============================================================
//  RANK-UP OVERLAY — Full cinematic dark screen
//  Fired when player's rank tier changes (e.g. E→D, D→C, etc.)
//  This is a bigger moment than a level-up — it's Solo Leveling
//  style "Class Change" energy.
// ============================================================

class RankUpOverlay extends StatefulWidget {
  const RankUpOverlay({
    super.key,
    required this.event,
    required this.onAcknowledge,
  });

  final RankUpEvent event;
  final VoidCallback onAcknowledge;

  @override
  State<RankUpOverlay> createState() => _RankUpOverlayState();
}

class _RankUpOverlayState extends State<RankUpOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fade;
  late Animation<double> _scale;
  late Animation<double> _pulse;

  bool _btnReady = false;

  @override
  void initState() {
    super.initState();

    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic),
    );
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _fadeCtrl.forward();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _btnReady = true);
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Color get _rankColor {
    switch (widget.event.toRank) {
      case 'D': return const Color(0xFF78909C);
      case 'C': return const Color(0xFF26C6DA);
      case 'B': return const Color(0xFF66BB6A);
      case 'A': return const Color(0xFFFFCA28);
      case 'S': return const Color(0xFF00E5FF);
      case 'GOD': return const Color(0xFFE040FB);
      default:   return AppColors.primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    final color = _rankColor;

    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([_fadeCtrl, _pulseCtrl]),
        builder: (context, _) {
          return Opacity(
            opacity: _fade.value,
            child: Stack(
              children: [
                // Full-screen deep black background with vignette glow
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.1),
                          radius: 0.85,
                          colors: [
                            color.withValues(alpha: 0.18 * _pulse.value),
                            Colors.black.withValues(alpha: 0.97),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Central card
                Center(
                  child: Transform.scale(
                    scale: _scale.value,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 28,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.70),
                          border: Border.all(
                            color: color.withValues(alpha: 0.70),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(
                                alpha: 0.30 * _pulse.value,
                              ),
                              blurRadius: 40,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // System label
                            Text(
                              '[SYSTEM NOTIFICATION]',
                              style: TextStyle(
                                color: color.withValues(alpha: 0.65),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.5,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Divider line
                            Container(
                              height: 1,
                              color: color.withValues(alpha: 0.35),
                            ),
                            const SizedBox(height: 18),

                            // RANK UP headline
                            Text(
                              'RANK UP',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: 2,
                                height: 1.0,
                                shadows: [
                                  Shadow(
                                    blurRadius: 28,
                                    color: color.withValues(
                                      alpha: 0.55 * _pulse.value,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Rank transition line
                            Row(
                              children: [
                                _RankBadge(
                                  rank: e.fromRank,
                                  color: Colors.white38,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: color,
                                    size: 20,
                                  ),
                                ),
                                _RankBadge(rank: e.toRank, color: color),
                              ],
                            ),
                            const SizedBox(height: 18),

                            // New Job label
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.08),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.40),
                                ),
                              ),
                              child: Text(
                                'JOB: ${e.newJobLabel}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Divider
                            Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                            const SizedBox(height: 14),

                            // Voice line
                            Text(
                              e.systemVoiceLine,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Acknowledge button at bottom
                Positioned(
                  bottom: 28,
                  left: 20,
                  right: 20,
                  child: AnimatedOpacity(
                    opacity: _btnReady ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 400),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onAcknowledge,
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: color.withValues(alpha: 0.75),
                              width: 1.2,
                            ),
                            gradient: LinearGradient(
                              colors: [
                                color.withValues(alpha: 0.15),
                                Colors.black,
                              ],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '[ACKNOWLEDGE]',
                            style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  final String rank;
  final Color color;
  const _RankBadge({required this.rank, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        color: color.withValues(alpha: 0.10),
      ),
      alignment: Alignment.center,
      child: Text(
        rank,
        style: TextStyle(
          color: color,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
