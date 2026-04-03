import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_provider.dart';
import 'ui/theme/app_colors.dart';

/// Full-screen lockout screen displayed when the hunter fails to complete
/// the Physical Foundation at midnight.
///
/// This screen is oppressive and unavoidable, with a countdown timer showing
/// the remaining penalty duration. All navigation is disabled while active.
///
/// **Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6**
class PenaltyZoneScreen extends StatefulWidget {
  /// Callback invoked when the penalty timer expires (reaches 00:00:00).
  final VoidCallback onExpired;

  const PenaltyZoneScreen({
    super.key,
    required this.onExpired,
  });

  @override
  State<PenaltyZoneScreen> createState() => _PenaltyZoneScreenState();
}

class _PenaltyZoneScreenState extends State<PenaltyZoneScreen> {
  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();

    return PopScope(
      // Prevent back button navigation (Requirement 4.3)
      canPop: false,
      child: Scaffold(
        // Deep Red background (Requirement 4.2)
        backgroundColor: AppColors.penaltyBackground,
        body: StreamBuilder<int>(
          // Update countdown every second (Requirement 4.4)
          stream: Stream.periodic(const Duration(seconds: 1), (count) => count),
          builder: (context, snapshot) {
            // Compute remaining duration
            final remaining = _computeRemaining(player);

            // Check if timer has expired
            if (remaining <= Duration.zero) {
              // Call onExpired callback (Requirement 4.6)
              WidgetsBinding.instance.addPostFrameCallback((_) {
                widget.onExpired();
              });
              return const SizedBox.shrink();
            }

            // Format as HH:MM:SS (Requirement 4.4)
            final timeString = _formatDuration(remaining);

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // System message
                  Text(
                    'PENALTY ZONE ACTIVE',
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.9),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Survival Timer (Requirement 4.4)
                  Text(
                    'SURVIVAL TIMER',
                    style: TextStyle(
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Countdown display (HH:MM:SS format)
                  Text(
                    timeString,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 4.0,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Consequence message
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'PHYSICAL FOUNDATION INCOMPLETE.\nFULL ACCESS SUSPENDED.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary.withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Computes the remaining penalty duration.
  ///
  /// Formula: Duration(hours: 4) - DateTime.now().difference(player.penaltyActivatedAt!)
  ///
  /// Returns Duration.zero if the penalty has expired or if state is invalid.
  Duration _computeRemaining(PlayerProvider player) {
    if (!player.inPenaltyZone || player.penaltyActivatedAt == null) {
      return Duration.zero;
    }

    final elapsed = DateTime.now().difference(player.penaltyActivatedAt!);
    final remaining = const Duration(hours: 4) - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Formats a Duration as a zero-padded HH:MM:SS string.
  ///
  /// Example: Duration(hours: 3, minutes: 45, seconds: 12) -> "03:45:12"
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
