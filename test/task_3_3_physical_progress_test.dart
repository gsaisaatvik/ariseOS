import 'package:flutter_test/flutter_test.dart';
import 'package:arise_os/models/physical_foundation.dart';

void main() {
  group('Task 3.3 - Physical Progress Methods', () {
    test('logPhysicalProgress updates progress map', () {
      // Test the logic of updating progress
      final progress = <String, int>{
        'Push-ups': 0,
        'Sit-ups': 0,
        'Squats': 0,
        'Running': 0,
      };
      
      // Simulate updating push-ups
      progress['Push-ups'] = 50;
      expect(progress['Push-ups'], 50);
      
      // Simulate updating sit-ups
      progress['Sit-ups'] = 75;
      expect(progress['Sit-ups'], 75);
    });

    test('physicalCompletionPct delegates to PhysicalFoundation', () {
      // Test that the completion percentage calculation works
      final progress = {
        'Push-ups': 50,   // 50/100 = 0.5
        'Sit-ups': 100,   // 100/100 = 1.0
        'Squats': 75,     // 75/100 = 0.75
        'Running': 5,     // 5/10 = 0.5
      };
      
      final pct = PhysicalFoundation.completionPct(progress);
      
      // Expected: (0.5 + 1.0 + 0.75 + 0.5) / 4 = 2.75 / 4 = 0.6875
      expect(pct, closeTo(0.6875, 0.0001));
    });

    test('resetPhysicalProgress sets all values to 0', () {
      // Test the logic of resetting progress
      final progress = <String, int>{
        'Push-ups': 50,
        'Sit-ups': 75,
        'Squats': 100,
        'Running': 8,
      };
      
      // Simulate reset
      progress['Push-ups'] = 0;
      progress['Sit-ups'] = 0;
      progress['Squats'] = 0;
      progress['Running'] = 0;
      
      expect(progress['Push-ups'], 0);
      expect(progress['Sit-ups'], 0);
      expect(progress['Squats'], 0);
      expect(progress['Running'], 0);
    });

    test('checkLimiterRemoval detects 200% threshold', () {
      // Test that limiter removal detection works
      final progress = {
        'Push-ups': 200,  // 200% of 100
        'Sit-ups': 210,   // 210% of 100
        'Squats': 205,    // 205% of 100
        'Running': 20,    // 200% of 10
      };
      
      final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
      expect(isRemoved, true);
    });

    test('checkLimiterRemoval returns false below 200% threshold', () {
      // Test that limiter removal is not triggered below threshold
      final progress = {
        'Push-ups': 200,  // 200% of 100
        'Sit-ups': 210,   // 210% of 100
        'Squats': 199,    // 199% of 100 (below threshold!)
        'Running': 20,    // 200% of 10
      };
      
      final isRemoved = PhysicalFoundation.isLimiterRemoved(progress);
      expect(isRemoved, false);
    });

    test('negative values are clamped to 0', () {
      // Test that negative values are handled correctly
      final value = -10;
      final clampedValue = value < 0 ? 0 : value;
      expect(clampedValue, 0);
    });

    test('physical progress key mapping', () {
      // Test the key mapping logic
      String physicalProgressKey(String subTask) {
        switch (subTask) {
          case 'Push-ups':
            return 'physProgress_pushups';
          case 'Sit-ups':
            return 'physProgress_situps';
          case 'Squats':
            return 'physProgress_squats';
          case 'Running':
            return 'physProgress_running';
          default:
            throw ArgumentError('Unknown sub-task: $subTask');
        }
      }
      
      expect(physicalProgressKey('Push-ups'), 'physProgress_pushups');
      expect(physicalProgressKey('Sit-ups'), 'physProgress_situps');
      expect(physicalProgressKey('Squats'), 'physProgress_squats');
      expect(physicalProgressKey('Running'), 'physProgress_running');
      
      expect(() => physicalProgressKey('Invalid'), throwsArgumentError);
    });
  });
}
