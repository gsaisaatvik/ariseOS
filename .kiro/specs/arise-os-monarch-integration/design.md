# Design Document: ARISE OS Monarch Integration

## Overview

This feature transforms ARISE OS from a general productivity tracker into a sentient life-management system modelled on the Solo Leveling universe. The core architectural shift is the **Dual-Mandatory Architecture**: the Status Screen becomes a hard-coded Physical Foundation quest (immutable), while the Quests Screen hosts two user-configurable cognitive/technical pillars that lock at midnight.

Supporting systems include:
- A **Penalty Zone** full-screen lockout for physical quest failure at Midnight Judgement
- A **Dual XP Economy** (Lifetime XP for rank, Wallet XP for spending)
- **STR / INT / PER** stat binding to the three growth pillars
- A **Limiter Removal** mechanic for 200% physical overload
- A **Holographic UI** aesthetic overhaul (cyan glow, true black, pulse animations)

The existing `PlayerProvider`, `CoreEngine`, `HiveService`, and screen files are all refactored in-place. No new top-level architecture is introduced; the Provider + Hive pattern is preserved.

---

## Architecture

### Dual-Mandatory Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Dashboard                            │
│  ┌──────────────────┐        ┌──────────────────────────┐   │
│  │  Status Screen   │        │      Quests Screen       │   │
│  │  (Pillar 1)      │        │  (Pillars 2 & 3)         │   │
│  │  Physical        │        │  Cognitive + Technical   │   │
│  │  Foundation      │        │  (Input → Locked)        │   │
│  │  [IMMUTABLE]     │        │  [CONFIGURABLE]          │   │
│  └──────────────────┘        └──────────────────────────┘   │
│                                                             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              PenaltyZoneScreen (overlay)             │   │
│  │              [FULL-SCREEN when inPenaltyZone=true]   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
         │                          │
         ▼                          ▼
  PlayerProvider              HiveService
  (ChangeNotifier)            (Hive boxes)
  - lifetimeXP                - settings box
  - walletXP                  - monarch_state box (new)
  - STR / INT / PER
  - inPenaltyZone
  - penaltyActivatedAt
  - limiterRemovedToday
         │
         ▼
  CoreEngine (refactored)
  - Midnight Judgement logic
  - Physical Foundation evaluation
  - Quest lock transition
```

### Midnight Judgement Flow

```
00:00 local time
      │
      ▼
CoreEngine.runMidnightJudgement()
      │
      ├─ Compute physicalCompletionPct
      │
      ├─ if pct < 100%
      │       └─ PlayerProvider.activatePenaltyZone()
      │              └─ persist penaltyActivatedAt + inPenaltyZone=true
      │
      ├─ if pct >= 100%
      │       └─ PlayerProvider.recordDayCleared()
      │              └─ streakDays++
      │
      ├─ Reset all Physical_Foundation progress to 0
      │
      └─ Lock Cognitive_Quest + Technical_Quest
             └─ persist lockedCognitiveQuest + lockedTechnicalQuest
```

### App Startup / State Recovery Flow

```
main() → HiveService.init()
       → PlayerProvider._initialize()
              │
              ├─ Read inPenaltyZone from HiveService
              ├─ if true: compute remaining = 4h - (now - penaltyActivatedAt)
              │     if remaining > 0 → stay in penalty zone
              │     if remaining <= 0 → auto-deactivate
              │
              ├─ Read lockedCognitiveQuest / lockedTechnicalQuest
              ├─ Read STR / INT / PER
              ├─ Read lifetimeXP / walletXP
              └─ notifyListeners()
       → RootDecider → Dashboard (or PenaltyZoneScreen if locked)
```

---

## Components and Interfaces

### 1. PlayerProvider (refactored)

New fields added to the existing `PlayerProvider`:

```dart
// Monarch fields
int _str = 0;          // Strength — bound to Physical Foundation
int _int = 0;          // Intelligence — bound to Technical Quest
int _per = 0;          // Perception — bound to Cognitive Quest

bool _inPenaltyZone = false;
DateTime? _penaltyActivatedAt;

// Dual XP (lifetimeXP already exists as _totalXP; walletXP already exists)
// Level formula changes to: floor(sqrt(lifetimeXP) / 10) + 1

// Physical Foundation progress (already exists as _questProgress map)
// Keys: 'Push-ups', 'Sit-ups', 'Squats', 'Running'
// Targets: 100, 100, 100, 10

// Limiter Removal
bool _limiterRemovedToday = false;
bool _overloadTitleAwarded = false;

// Locked Mandatory Quests
int? _lockedCognitiveDurationMinutes;
String? _lockedTechnicalTask;
bool _cognitiveLocked = false;
bool _technicalLocked = false;
bool _cognitiveCompleted = false;
bool _technicalCompleted = false;

// Tomorrow's configured quests (pre-lock)
int? _pendingCognitiveDurationMinutes;
String? _pendingTechnicalTask;
```

New public methods:

```dart
// Physical Foundation
void logPhysicalProgress(String subTask, int value);
double get physicalCompletionPct;  // mean of 4 ratios

// Stat binding
void awardSTR(int amount);
void awardINT(int amount);
void awardPER(int amount);
int get str;
int get intStat;
int get per;

// Penalty Zone
void activatePenaltyZone();
void deactivatePenaltyZone();
bool get inPenaltyZone;
Duration? get penaltyRemainingDuration;

// Dual XP (level formula change)
// _calculateLevel now uses: floor(sqrt(xp) / 10) + 1

// Quest configuration
void setPendingCognitiveQuest(int durationMinutes);
void setPendingTechnicalQuest(String task);
void lockMandatoryQuests();  // called at midnight
void completeCognitiveQuest();
void completeTechnicalQuest();

// Limiter Removal
void checkLimiterRemoval();  // called after any physical progress log
bool get limiterRemovedToday;
bool get overloadTitleAwarded;
```

### 2. CoreEngine (refactored)

The existing `CoreEngine` is extended with Midnight Judgement logic:

```dart
class CoreEngine {
  // Existing fields preserved

  /// Called by a timer or app lifecycle event at local midnight.
  Future<void> runMidnightJudgement(PlayerProvider player) async {
    final pct = player.physicalCompletionPct;
    if (pct < 1.0) {
      player.activatePenaltyZone();
    } else {
      player.recordDayCleared();
    }
    player.resetPhysicalProgress();
    player.lockMandatoryQuests();
  }
}
```

Midnight scheduling is handled by a `Timer` set in `PlayerProvider._initialize()` to fire at the next local midnight, and rescheduled each day.

### 3. HiveService (schema additions)

A new `monarch_state` Hive box is added to isolate Monarch-specific persistence from the existing `settings` box. This avoids key collisions and makes migration cleaner.

```dart
static const String monarchStateBox = 'monarch_state';
```

Keys in `monarch_state`:

| Key | Type | Description |
|-----|------|-------------|
| `inPenaltyZone` | bool | Whether penalty zone is active |
| `penaltyActivatedAt` | String (ISO8601) | Timestamp of penalty activation |
| `physProgress_pushups` | int | Current push-up count |
| `physProgress_situps` | int | Current sit-up count |
| `physProgress_squats` | int | Current squat count |
| `physProgress_running` | int | Current running distance (tenths of km) |
| `str` | int | STR stat value |
| `intStat` | int | INT stat value |
| `per` | int | PER stat value |
| `pendingCognitiveMins` | int | Tomorrow's cognitive quest duration |
| `pendingTechnicalTask` | String | Tomorrow's technical quest task |
| `lockedCognitiveMins` | int | Today's locked cognitive duration |
| `lockedTechnicalTask` | String | Today's locked technical task |
| `cognitiveLocked` | bool | Whether cognitive quest is locked |
| `technicalLocked` | bool | Whether technical quest is locked |
| `cognitiveCompleted` | bool | Whether cognitive quest is completed today |
| `technicalCompleted` | bool | Whether technical quest is completed today |
| `limiterRemovedToday` | bool | Whether limiter removal fired today |
| `limiterRemovedDate` | String | Date string for daily reset |
| `overloadTitleAwarded` | bool | Whether Overload_Title has been permanently awarded |

### 4. PenaltyZoneScreen (new widget)

```dart
class PenaltyZoneScreen extends StatefulWidget {
  // Full-screen lockout widget
  // Background: Color(0xFF1A0000)
  // Displays: Survival_Timer (HH:MM:SS countdown)
  // Disables: all navigation
}
```

Integrated into `Dashboard` as a `Stack` overlay — when `player.inPenaltyZone` is true, `PenaltyZoneScreen` is rendered on top of all other content with `Positioned.fill` and `IgnorePointer(ignoring: false)` to block all taps.

```dart
// In Dashboard.build():
if (player.inPenaltyZone)
  PenaltyZoneScreen(onExpired: () => player.deactivatePenaltyZone())
```

The `Survival_Timer` uses a `StreamBuilder` on a `Stream.periodic(Duration(seconds: 1))` to update the countdown. The remaining duration is computed as:

```dart
Duration remaining = const Duration(hours: 4) - 
    DateTime.now().difference(player.penaltyActivatedAt!);
```

### 5. QuestsScreen (refactored)

The existing `QuestsScreen` is replaced with a new implementation that handles the Input Mode / Locked state machine:

```dart
// Quest slot state machine:
// UNLOCKED (Input Mode) → [midnight] → LOCKED → [completion] → COMPLETED

class _QuestSlotState {
  final bool isLocked;
  final bool isCompleted;
  final String? displayValue;  // duration or task description
}
```

Quest info badges use `TweenAnimationBuilder` for pulse animation:

```dart
TweenAnimationBuilder<double>(
  tween: Tween(begin: 0.6, end: 1.0),
  duration: const Duration(milliseconds: 900),
  builder: (context, opacity, child) => Opacity(opacity: opacity, child: child),
  onEnd: () => setState(() => _pulseForward = !_pulseForward),
)
```

### 6. StatusScreen (refactored)

The existing `StatusScreen` is replaced with a Physical Foundation-focused implementation:

```dart
// Hard-coded quest definition (immutable)
static const List<_PhysSubTask> _subTasks = [
  _PhysSubTask(key: 'Push-ups', label: '100 Push-ups', target: 100),
  _PhysSubTask(key: 'Sit-ups',  label: '100 Sit-ups',  target: 100),
  _PhysSubTask(key: 'Squats',   label: '100 Squats',   target: 100),
  _PhysSubTask(key: 'Running',  label: '10 km Running', target: 10),
];
```

Each sub-task renders a `TextFormField` with `keyboardType: TextInputType.number`. On change, `player.logPhysicalProgress(key, value)` is called immediately (no submit button needed for progress logging).

### 7. Holographic UI Theme System

#### AppColors additions

```dart
// Monarch additions to AppColors
static const Color monarchBackground = Color(0xFF000000);      // True Black
static const Color penaltyBackground = Color(0xFF1A0000);      // Deep Red
static const Color cyanGlow = Color(0xFF00FFFF);               // Cyan border/glow
static const Color cyanGlowDim = Color(0x4400FFFF);            // Dim cyan for shadows
```

#### Glow card decoration

A reusable `glowCardDecoration` helper:

```dart
BoxDecoration glowCardDecoration({bool penalty = false}) => BoxDecoration(
  color: Colors.black,
  border: Border.all(color: AppColors.cyanGlow, width: 1.2),
  boxShadow: [
    BoxShadow(
      color: AppColors.cyanGlow.withOpacity(0.35),
      blurRadius: 15.0,
      spreadRadius: 1,
    ),
  ],
);
```

#### Quest Cleared Overlay

```dart
class QuestClearedOverlay extends StatelessWidget {
  // Full-screen overlay with TweenAnimationBuilder fade
  // Text: "QUEST CLEARED.\nREWARDS DISTRIBUTED."
  // Auto-dismisses after 2.5 seconds
}
```

#### Limiter Removed Overlay

```dart
class LimiterRemovedOverlay extends StatelessWidget {
  // Full-screen overlay
  // Text: "LIMITER REMOVED"
  // Cyan glow effect, auto-dismisses after 3 seconds
}
```

---

## Data Models

### Physical Foundation Targets (compile-time constants)

```dart
class PhysicalFoundation {
  static const Map<String, int> targets = {
    'Push-ups': 100,
    'Sit-ups':  100,
    'Squats':   100,
    'Running':  10,   // km
  };

  static double completionPct(Map<String, int> progress) {
    if (targets.isEmpty) return 0.0;
    double sum = 0.0;
    for (final entry in targets.entries) {
      final val = progress[entry.key] ?? 0;
      sum += (val / entry.value).clamp(0.0, 1.0);
    }
    return sum / targets.length;
  }

  static bool isLimiterRemoved(Map<String, int> progress) {
    return targets.entries.every((e) => (progress[e.key] ?? 0) >= e.value * 2);
  }
}
```

### Level Formula

```dart
// New formula (replaces existing _calculateLevel)
static int calculateLevel(int lifetimeXP) {
  return (math.sqrt(lifetimeXP.toDouble()) / 10).floor() + 1;
}
```

### Stat Reward Constants

```dart
class MonarchRewards {
  static const int strPerPhysicalCompletion = 3;
  static const int intPerTechnicalCompletion = 3;
  static const int perPerCognitiveCompletion = 3;
  static const int statPointsPerLimiterRemoval = 5;
  static const int penaltyZoneDurationHours = 4;
}
```

### Quest Lock State

```dart
enum QuestLockState { unlocked, locked, completed }
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system — essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Physical Foundation immutability

*For any* sequence of user interactions on the Status Screen, the four Physical Foundation sub-tasks (Push-ups, Sit-ups, Squats, Running) shall always be present, in the same order, with the same targets.

**Validates: Requirements 1.4**

---

### Property 2: Physical progress display round-trip

*For any* valid integer progress value logged for a Physical Foundation sub-task, the value displayed on the Status Screen shall equal the logged value immediately after the call to `logPhysicalProgress`.

**Validates: Requirements 1.5**

---

### Property 3: Physical completion percentage formula

*For any* four non-negative progress values (pushups, situps, squats, running), the displayed completion percentage shall equal `mean([min(p/t, 1.0) for each sub-task]) * 100`, where t is the target for each sub-task.

**Validates: Requirements 1.6**

---

### Property 4: Quest input validation

*For any* integer duration outside the range [1, 480], submitting it as a Cognitive Quest duration shall result in a validation error being displayed and the value not being persisted to HiveService.

**Validates: Requirements 2.7**

---

### Property 5: Quest configuration persistence round-trip

*For any* valid Cognitive Quest duration in [1, 480] and any non-empty Technical Quest task string, persisting them via `setPendingCognitiveQuest` / `setPendingTechnicalQuest` and then reading from HiveService shall return the same values.

**Validates: Requirements 2.3, 9.3**

---

### Property 6: Midnight Judgement — penalty activation

*For any* Physical Foundation progress state where `physicalCompletionPct < 1.0`, running `CoreEngine.runMidnightJudgement` shall set `player.inPenaltyZone` to true.

**Validates: Requirements 3.1, 3.2**

---

### Property 7: Midnight Judgement — streak extension

*For any* Physical Foundation progress state where `physicalCompletionPct >= 1.0`, running `CoreEngine.runMidnightJudgement` shall increment `player.streakDays` by exactly 1.

**Validates: Requirements 3.3**

---

### Property 8: Midnight Judgement — progress reset

*For any* Physical Foundation progress state (any combination of values), running `CoreEngine.runMidnightJudgement` shall set all four sub-task progress values to zero.

**Validates: Requirements 3.4**

---

### Property 9: Penalty Zone survival timer format

*For any* remaining duration in seconds in the range [0, 14400], the formatted Survival Timer string shall match the pattern `HH:MM:SS` where HH, MM, SS are zero-padded integers.

**Validates: Requirements 4.4**

---

### Property 10: Penalty Zone state recovery

*For any* penalty activation timestamp T where `DateTime.now().difference(T) < Duration(hours: 4)`, app initialization shall set `inPenaltyZone = true` and `penaltyRemainingDuration` shall equal `Duration(hours: 4) - (now - T)` within a 1-second tolerance.

**Validates: Requirements 4.7, 4.8, 9.2**

---

### Property 11: Penalty Zone deactivation

*For any* penalty zone state where the elapsed time since `penaltyActivatedAt` is >= 4 hours, the system shall set `inPenaltyZone = false`.

**Validates: Requirements 4.6**

---

### Property 12: Level formula correctness

*For any* non-negative integer `lifetimeXP`, `PlayerProvider.calculateLevel(lifetimeXP)` shall equal `(sqrt(lifetimeXP) / 10).floor() + 1`.

**Validates: Requirements 5.2**

---

### Property 13: Dual XP simultaneous award

*For any* positive XP amount earned from a quest completion, both `lifetimeXP` and `walletXP` shall each increase by exactly that amount.

**Validates: Requirements 5.3**

---

### Property 14: Lifetime XP monotonicity

*For any* sequence of operations (quest completions, penalties, spending), `lifetimeXP` shall never decrease.

**Validates: Requirements 5.4**

---

### Property 15: Wallet XP floor invariant

*For any* sequence of penalty operations, `walletXP` shall never fall below -500.

**Validates: Requirements 5.6**

---

### Property 16: Stat binding correctness

*For any* initial STR, INT, or PER value and any positive reward amount, completing the corresponding quest pillar shall increase the respective stat by exactly the reward amount, and HiveService shall immediately reflect the new value.

**Validates: Requirements 6.1, 6.2, 6.3, 6.4**

---

### Property 17: Limiter Removal threshold

*For any* Physical Foundation progress state where every sub-task value is >= 200% of its target, `checkLimiterRemoval()` shall trigger a Secret Quest Event (awarding 5 stat points and setting `limiterRemovedToday = true`).

**Validates: Requirements 7.1, 7.2**

---

### Property 18: Limiter Removal idempotence per day

*For any* number of times the 200% threshold is crossed in a single day, the Secret Quest Event shall fire at most once (stat points awarded exactly once, `limiterRemovedToday` remains true after the first trigger).

**Validates: Requirements 7.4, 9.6**

---

### Property 19: Physical progress persistence round-trip

*For any* valid progress value logged for any Physical Foundation sub-task, reading the corresponding key from HiveService `monarch_state` box shall return the same value immediately after the log call.

**Validates: Requirements 9.1**

---

## Error Handling

### Invalid Physical Progress Input
- Non-numeric input in a sub-task field: ignore silently, keep previous value
- Negative values: clamp to 0
- Values exceeding 200% of target: accepted (required for Limiter Removal), capped at display level only

### Cognitive Quest Validation Errors
- Duration < 1 or > 480 minutes: display inline error text below the input field; do not persist
- Empty string: treat as < 1 minute, show same validation error

### Penalty Zone Edge Cases
- App restarted after 4-hour window has elapsed: auto-deactivate on init, do not show penalty zone
- `penaltyActivatedAt` is null but `inPenaltyZone` is true (corrupted state): deactivate penalty zone and log a system warning
- Clock skew / timezone change: use `DateTime.now()` consistently; no UTC conversion for penalty timer

### Midnight Judgement Scheduling
- App was closed at midnight: `_checkResets()` in `PlayerProvider._initialize()` detects the missed midnight via `lastDailyReset` date comparison and runs the judgement retroactively
- Multiple missed days: apply judgement for the most recent missed midnight only (one penalty zone activation maximum per init)

### HiveService Failures
- Box not open: wrap all `HiveService.monarchState` accesses in try/catch; fall back to in-memory defaults
- Corrupted values (wrong type): use `defaultValue` parameter on all `.get()` calls

---

## Testing Strategy

### Unit Tests (example-based)

Focus on specific scenarios and edge cases:

- `PhysicalFoundation.completionPct` with all zeros, all at target, mixed values
- `PhysicalFoundation.isLimiterRemoved` with exactly 200%, just below 200%, above 200%
- `PlayerProvider.calculateLevel` with XP = 0, 100, 10000, 1000000
- `PenaltyZoneScreen` renders with background `Color(0xFF1A0000)`
- `QuestsScreen` renders two quest slots in Input Mode when not locked
- `QuestsScreen` renders read-only slots when locked
- `QuestClearedOverlay` displays correct text
- `LimiterRemovedOverlay` displays "LIMITER REMOVED"
- Overload Title is assigned on first Secret Quest Event and not re-assigned on second

### Property-Based Tests

Using the `fast_check` Dart package (or `dart_test` with custom generators). Each property test runs a minimum of 100 iterations.

**Tag format: `Feature: arise-os-monarch-integration, Property {N}: {property_text}`**

| Property | Generator | Assertion |
|----------|-----------|-----------|
| P1: Sub-task immutability | Random tap sequences | Sub-tasks unchanged |
| P2: Progress display round-trip | Random int in [0, 500] | Displayed == logged |
| P3: Completion pct formula | 4 random ints [0, 300] | Pct == formula result |
| P4: Quest validation | Random int outside [1, 480] | Error shown, not persisted |
| P5: Quest config persistence | Random valid duration + task | Read == written |
| P6: Penalty activation | Random pct < 1.0 | inPenaltyZone = true |
| P7: Streak extension | Random pct >= 1.0 | streakDays++ |
| P8: Progress reset | Random progress state | All zeros after judgement |
| P9: Timer format | Random seconds [0, 14400] | Matches HH:MM:SS regex |
| P10: State recovery | Random timestamp within 4h | Correct remaining duration |
| P11: Penalty deactivation | Random timestamp >= 4h ago | inPenaltyZone = false |
| P12: Level formula | Random non-negative int | Matches formula |
| P13: Dual XP award | Random positive XP | Both fields increase by amount |
| P14: Lifetime XP monotonicity | Random op sequences | lifetimeXP never decreases |
| P15: Wallet floor | Random penalty sequences | walletXP >= -500 |
| P16: Stat binding | Random stat + reward | Stat increases by reward, Hive updated |
| P17: Limiter threshold | Random values all >= 200% | Event triggered |
| P18: Limiter idempotence | Random repeat count | Event fires exactly once |
| P19: Progress persistence | Random valid progress | Hive reflects value |

### Integration Tests

- App cold start with `inPenaltyZone=true` and valid timestamp → PenaltyZoneScreen shown
- App cold start with `inPenaltyZone=true` and expired timestamp → Dashboard shown
- Full Midnight Judgement cycle: set progress, trigger judgement, verify all state transitions
- Limiter Removal full flow: set 200% progress, verify stat points + title + overlay
