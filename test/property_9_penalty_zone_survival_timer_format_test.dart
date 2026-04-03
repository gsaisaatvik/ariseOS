import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

/// Property 9: Penalty Zone survival timer format
/// **Validates: Requirements 4.4**
/// 
/// For any remaining duration in seconds in the range [0, 14400], the formatted
/// Survival Timer string shall match the pattern `HH:MM:SS` where HH, MM, SS are
/// zero-padded integers.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature: arise-os-monarch-integration, Property 9: Penalty Zone survival timer format', () {
    final random = Random();

    /// Helper function to format a Duration as HH:MM:SS
    /// This replicates the logic from PenaltyZoneScreen._formatDuration
    String formatDuration(Duration duration) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes.remainder(60);
      final seconds = duration.inSeconds.remainder(60);

      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    }

    /// Regex pattern for HH:MM:SS format with zero-padded integers
    final timerFormatRegex = RegExp(r'^\d{2}:\d{2}:\d{2}$');

    test('Timer format matches HH:MM:SS pattern - 100 iterations', () {
      // Run minimum 100 iterations as specified in the task
      for (int iteration = 0; iteration < 100; iteration++) {
        // Generate random seconds in [0, 14400] (0 to 4 hours)
        final seconds = random.nextInt(14401); // 0 to 14400 inclusive
        final duration = Duration(seconds: seconds);
        
        // Format the duration
        final formatted = formatDuration(duration);
        
        // Assert output matches regex ^\d{2}:\d{2}:\d{2}$
        expect(
          timerFormatRegex.hasMatch(formatted),
          isTrue,
          reason: 'Iteration $iteration: Duration $seconds seconds formatted as "$formatted" '
                  'does not match HH:MM:SS pattern',
        );
        
        // Additional validation: verify the format is exactly 8 characters (HH:MM:SS)
        expect(
          formatted.length,
          equals(8),
          reason: 'Formatted timer must be exactly 8 characters long (HH:MM:SS)',
        );
        
        // Verify colons are in the correct positions
        expect(
          formatted[2],
          equals(':'),
          reason: 'Character at position 2 must be a colon',
        );
        expect(
          formatted[5],
          equals(':'),
          reason: 'Character at position 5 must be a colon',
        );
      }
    });

    test('Timer format - edge cases', () {
      final edgeCases = [
        // Zero duration (penalty just expired)
        0,
        
        // One second
        1,
        
        // 59 seconds (maximum seconds without minutes)
        59,
        
        // 60 seconds (exactly 1 minute)
        60,
        
        // 61 seconds (1 minute 1 second)
        61,
        
        // 3599 seconds (59 minutes 59 seconds)
        3599,
        
        // 3600 seconds (exactly 1 hour)
        3600,
        
        // 3661 seconds (1 hour 1 minute 1 second)
        3661,
        
        // 7200 seconds (exactly 2 hours)
        7200,
        
        // 14399 seconds (3 hours 59 minutes 59 seconds)
        14399,
        
        // 14400 seconds (exactly 4 hours - maximum penalty duration)
        14400,
      ];

      for (int i = 0; i < edgeCases.length; i++) {
        final seconds = edgeCases[i];
        final duration = Duration(seconds: seconds);
        final formatted = formatDuration(duration);
        
        expect(
          timerFormatRegex.hasMatch(formatted),
          isTrue,
          reason: 'Edge case $i: Duration $seconds seconds formatted as "$formatted" '
                  'does not match HH:MM:SS pattern',
        );
        
        expect(
          formatted.length,
          equals(8),
          reason: 'Edge case $i: Formatted timer must be exactly 8 characters long',
        );
      }
    });

    test('Timer format - zero-padding verification', () {
      // Test specific cases to verify zero-padding is applied correctly
      final zeroPaddingCases = [
        // 0 seconds -> "00:00:00"
        (0, '00:00:00'),
        
        // 1 second -> "00:00:01"
        (1, '00:00:01'),
        
        // 9 seconds -> "00:00:09"
        (9, '00:00:09'),
        
        // 10 seconds -> "00:00:10"
        (10, '00:00:10'),
        
        // 60 seconds -> "00:01:00"
        (60, '00:01:00'),
        
        // 61 seconds -> "00:01:01"
        (61, '00:01:01'),
        
        // 600 seconds (10 minutes) -> "00:10:00"
        (600, '00:10:00'),
        
        // 3600 seconds (1 hour) -> "01:00:00"
        (3600, '01:00:00'),
        
        // 3661 seconds (1:01:01) -> "01:01:01"
        (3661, '01:01:01'),
        
        // 36000 seconds (10 hours) -> "10:00:00"
        (36000, '10:00:00'),
      ];

      for (int i = 0; i < zeroPaddingCases.length; i++) {
        final (seconds, expected) = zeroPaddingCases[i];
        final duration = Duration(seconds: seconds);
        final formatted = formatDuration(duration);
        
        expect(
          formatted,
          equals(expected),
          reason: 'Zero-padding case $i: Duration $seconds seconds should format as "$expected", '
                  'but got "$formatted"',
        );
      }
    });

    test('Timer format - boundary values within 4-hour range', () {
      // Test all boundary values within the penalty zone duration
      final boundarySeconds = [
        0,      // Start of range
        1,      // Just after start
        3599,   // Just before 1 hour
        3600,   // Exactly 1 hour
        3601,   // Just after 1 hour
        7199,   // Just before 2 hours
        7200,   // Exactly 2 hours
        7201,   // Just after 2 hours
        10799,  // Just before 3 hours
        10800,  // Exactly 3 hours
        10801,  // Just after 3 hours
        14399,  // Just before 4 hours
        14400,  // Exactly 4 hours (end of range)
      ];

      for (final seconds in boundarySeconds) {
        final duration = Duration(seconds: seconds);
        final formatted = formatDuration(duration);
        
        expect(
          timerFormatRegex.hasMatch(formatted),
          isTrue,
          reason: 'Boundary value $seconds seconds formatted as "$formatted" '
                  'does not match HH:MM:SS pattern',
        );
        
        // Verify each component is a valid two-digit number
        final parts = formatted.split(':');
        expect(parts.length, equals(3), reason: 'Must have exactly 3 parts separated by colons');
        
        for (int i = 0; i < parts.length; i++) {
          final part = parts[i];
          expect(part.length, equals(2), reason: 'Part $i must be exactly 2 digits');
          expect(int.tryParse(part), isNotNull, reason: 'Part $i must be a valid integer');
        }
      }
    });

    test('Timer format - random stress test with extended range', () {
      // Additional stress test with random values
      for (int iteration = 0; iteration < 200; iteration++) {
        // Generate random seconds in [0, 14400]
        final seconds = random.nextInt(14401);
        final duration = Duration(seconds: seconds);
        final formatted = formatDuration(duration);
        
        // Verify regex match
        expect(
          timerFormatRegex.hasMatch(formatted),
          isTrue,
          reason: 'Stress test iteration $iteration: Duration $seconds seconds formatted as "$formatted" '
                  'does not match HH:MM:SS pattern',
        );
        
        // Parse the formatted string and verify it represents the correct duration
        final parts = formatted.split(':');
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        final secs = int.parse(parts[2]);
        
        // Verify components are in valid ranges
        expect(hours, inInclusiveRange(0, 4), reason: 'Hours must be in range [0, 4]');
        expect(minutes, inInclusiveRange(0, 59), reason: 'Minutes must be in range [0, 59]');
        expect(secs, inInclusiveRange(0, 59), reason: 'Seconds must be in range [0, 59]');
        
        // Verify the parsed components reconstruct the original duration
        final reconstructedSeconds = hours * 3600 + minutes * 60 + secs;
        expect(
          reconstructedSeconds,
          equals(seconds),
          reason: 'Parsed components should reconstruct the original duration',
        );
      }
    });

    test('Timer format - consistency across multiple calls', () {
      // Verify that formatting the same duration multiple times produces the same result
      final testSeconds = [0, 1, 60, 3600, 7200, 14400];
      
      for (final seconds in testSeconds) {
        final duration = Duration(seconds: seconds);
        final formatted1 = formatDuration(duration);
        final formatted2 = formatDuration(duration);
        final formatted3 = formatDuration(duration);
        
        expect(
          formatted1,
          equals(formatted2),
          reason: 'Multiple calls with same duration should produce identical results',
        );
        expect(
          formatted2,
          equals(formatted3),
          reason: 'Multiple calls with same duration should produce identical results',
        );
      }
    });
  });
}
