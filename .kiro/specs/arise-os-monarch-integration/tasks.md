# Implementation Plan: ARISE OS Monarch Integration

## Overview

Implement the Dual-Mandatory Architecture, Penalty Zone, Dual XP Economy, STR/INT/PER stat binding, Limiter Removal, and Holographic UI overhaul. Tasks are ordered by dependency: data layer → logic layer → UI layer → tests.

## Tasks

- [ ] 1. HiveService — add monarch_state box
  - [x] 1.1 Open `monarch_state` Hive box in `HiveService.init()` and expose a static getter
    - Add `static const String monarchStateBox = 'monarch_state'` constant
    - Call `await Hive.openBox(monarchStateBox)` inside `init()` after existing boxes
    - Add `static Box get monarchState => Hive.box(monarchStateBox)` getter
    - _Requirements: 9.1, 9.2, 9.3, 9.4_

  - [x] 1.2 Write property test for physical progress persistence round-trip (Property 19)
    - **Property 19: Physical progress persistence round-trip**
    - **Validates: Requirements 9.1**
    - Use `fast_check` to generate random valid progress values for each sub-task key
    - Assert `HiveService.monarchState.get(key)` equals the written value immediately after `put`

- [ ] 2. PhysicalFoundation constants and helpers
  - [x] 2.1 Create `lib/models/physical_foundation.dart` with compile-time constants and pure helper functions
    - Define `static const Map<String, int> targets` with Push-ups: 100, Sit-ups: 100, Squats: 100, Running: 10
    - Implement `static double completionPct(Map<String, int> progress)` — mean of clamped ratios
    - Implement `static bool isLimiterRemoved(Map<String, int> progress)` — all sub-tasks >= 200% of target
    - _Requirements: 1.2, 1.6, 7.1_

  - [x] 2.2 Write property test for completion percentage formula (Property 3)
    - **Property 3: Physical completion percentage formula**
    - **Validates: Requirements 1.6**
    - Generate 4 random ints in [0, 300]; assert `completionPct` equals `mean([min(p/t, 1.0)])` formula

  - [x] 2.3 Write property test for Physical Foundation immutability (Property 1)
    - **Property 1: Physical Foundation sub-task immutability**
    - **Validates: Requirements 1.4**
    - Assert `PhysicalFoundation.targets.keys.toList()` always equals `['Push-ups', 'Sit-ups', 'Squats', 'Running']` and values are unchanged regardless of any external state

  - [x] 2.4 Create `lib/models/monarch_rewards.dart` with stat reward constants
    - Define `MonarchRewards` class with `strPerPhysicalCompletion = 3`, `intPerTechnicalCompletion = 3`, `perPerCognitiveCompletion = 3`, `statPointsPerLimiterRemoval = 5`, `penaltyZoneDurationHours = 4`
    - Define `QuestLockState` enum: `unlocked`, `locked`, `completed`
    - _Requirements: 6.1, 6.2, 6.3, 7.2_

- [ ] 3. PlayerProvider — Monarch fields and core methods
  - [x] 3.1 Add Monarch state fields to `PlayerProvider`
    - Add `_str`, `_int`, `_per` int fields (Strength, Intelligence, Perception)
    - Add `_inPenaltyZone`, `_penaltyActivatedAt` fields
    - Add `_limiterRemovedToday`, `_overloadTitleAwarded` bool fields
    - Add `_lockedCognitiveDurationMinutes`, `_lockedTechnicalTask`, `_cognitiveLocked`, `_technicalLocked`, `_cognitiveCompleted`, `_technicalCompleted` fields
    - Add `_pendingCognitiveDurationMinutes`, `_pendingTechnicalTask` fields
    - _Requirements: 5.1, 6.1, 6.2, 6.3, 4.1, 7.3, 2.2_

  - [x] 3.2 Load Monarch fields from `HiveService.monarchState` in `_initialize()`
    - Read all monarch_state keys with safe `defaultValue` fallbacks
    - On init, check `inPenaltyZone`: if true, compute remaining = 4h − (now − penaltyActivatedAt); auto-deactivate if elapsed >= 4h
    - Handle corrupted state (null `penaltyActivatedAt` with `inPenaltyZone=true`): deactivate and log warning
    - Schedule midnight timer via `Timer` to call `CoreEngine.runMidnightJudgement`
    - _Requirements: 4.7, 4.8, 9.2, 9.5_

  - [x] 3.3 Implement `logPhysicalProgress`, `physicalCompletionPct`, and `resetPhysicalProgress`
    - `logPhysicalProgress(String subTask, int value)`: update `_questProgress[subTask]`, persist to `monarchState`, call `checkLimiterRemoval()`, `notifyListeners()`
    - `double get physicalCompletionPct`: delegate to `PhysicalFoundation.completionPct(_questProgress)`
    - `resetPhysicalProgress()`: set all four keys to 0, persist, `notifyListeners()`
    - _Requirements: 1.3, 1.5, 1.6, 3.4_

  - [x] 3.4 Write property test for progress display round-trip (Property 2)
    - **Property 2: Physical progress display round-trip**
    - **Validates: Requirements 1.5**
    - Generate random int in [0, 500]; call `logPhysicalProgress`; assert `questProgress[key]` equals logged value

  - [x] 3.5 Implement `awardSTR`, `awardINT`, `awardPER` and their getters
    - Each method increments the respective field, persists to `monarchState`, calls `notifyListeners()`
    - Expose `int get str`, `int get intStat`, `int get per`
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [x] 3.6 Write property test for stat binding correctness (Property 16)
    - **Property 16: Stat binding correctness**
    - **Validates: Requirements 6.1, 6.2, 6.3, 6.4**
    - Generate random initial stat value and positive reward; call award method; assert stat increased by exactly reward amount and `monarchState.get(key)` reflects new value

  - [x] 3.7 Implement `activatePenaltyZone` and `deactivatePenaltyZone`
    - `activatePenaltyZone()`: set `_inPenaltyZone=true`, `_penaltyActivatedAt=DateTime.now()`, persist both to `monarchState`, `notifyListeners()`
    - `deactivatePenaltyZone()`: set `_inPenaltyZone=false`, clear `penaltyActivatedAt` in `monarchState`, `notifyListeners()`
    - Expose `bool get inPenaltyZone`, `Duration? get penaltyRemainingDuration`
    - _Requirements: 4.1, 4.5, 4.6, 4.7, 9.2_

  - [x] 3.8 Write property test for Penalty Zone state recovery (Property 10)
    - **Property 10: Penalty Zone state recovery**
    - **Validates: Requirements 4.7, 4.8, 9.2**
    - Generate random timestamp T where `now - T < 4h`; simulate init reading that timestamp; assert `inPenaltyZone=true` and `penaltyRemainingDuration` equals `4h - (now - T)` within 1-second tolerance

  - [x] 3.9 Write property test for Penalty Zone deactivation (Property 11)
    - **Property 11: Penalty Zone deactivation**
    - **Validates: Requirements 4.6**
    - Generate random timestamp T where `now - T >= 4h`; simulate init; assert `inPenaltyZone=false`

  - [x] 3.10 Implement `setPendingCognitiveQuest`, `setPendingTechnicalQuest`, `lockMandatoryQuests`, `completeCognitiveQuest`, `completeTechnicalQuest`
    - `setPendingCognitiveQuest(int mins)`: validate [1, 480], persist to `monarchState`, `notifyListeners()`
    - `setPendingTechnicalQuest(String task)`: persist to `monarchState`, `notifyListeners()`
    - `lockMandatoryQuests()`: copy pending → locked fields, set `_cognitiveLocked=true`, `_technicalLocked=true`, persist, `notifyListeners()`
    - `completeCognitiveQuest()` / `completeTechnicalQuest()`: set completed flags, call `awardPER`/`awardINT`, persist, `notifyListeners()`
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 2.6, 3.5, 9.3, 9.4_

  - [x] 3.11 Write property test for quest configuration persistence round-trip (Property 5)
    - **Property 5: Quest configuration persistence round-trip**
    - **Validates: Requirements 2.3, 9.3**
    - Generate random valid duration in [1, 480] and non-empty task string; call set methods; assert `monarchState` returns same values

  - [x] 3.12 Update `_calculateLevel` to use new formula: `floor(sqrt(lifetimeXP) / 10) + 1`
    - Replace existing `math.sqrt(xp.toDouble()).floor()` with `(math.sqrt(xp.toDouble()) / 10).floor() + 1`
    - Add static `calculateLevel(int lifetimeXP)` public method for testability
    - _Requirements: 5.2_

  - [x] 3.13 Write property test for level formula correctness (Property 12)
    - **Property 12: Level formula correctness**
    - **Validates: Requirements 5.2**
    - Generate random non-negative int; assert `PlayerProvider.calculateLevel(xp)` equals `(sqrt(xp) / 10).floor() + 1`

  - [x] 3.14 Implement dual XP award and wallet floor enforcement
    - Update `addXP` / `_internalAddXP` to increment both `_totalXP` (lifetimeXP) and `_walletXP` simultaneously
    - Ensure `_totalXP` is never decremented in any code path
    - Enforce `_walletXP >= _walletFloor` (-500) in `_applyWalletPenalty`
    - _Requirements: 5.1, 5.3, 5.4, 5.5, 5.6_

  - [x] 3.15 Write property test for dual XP simultaneous award (Property 13)
    - **Property 13: Dual XP simultaneous award**
    - **Validates: Requirements 5.3**
    - Generate random positive XP amount; call `addXP`; assert both `totalXP` and `walletXP` each increased by exactly that amount

  - [x] 3.16 Write property test for Lifetime XP monotonicity (Property 14)
    - **Property 14: Lifetime XP monotonicity**
    - **Validates: Requirements 5.4**
    - Generate random sequence of `addXP` and penalty operations; assert `totalXP` never decreases across the sequence

  - [x] 3.17 Write property test for Wallet XP floor invariant (Property 15)
    - **Property 15: Wallet XP floor invariant**
    - **Validates: Requirements 5.6**
    - Generate random sequence of penalty operations; assert `walletXP >= -500` after each operation

  - [x] 3.18 Implement `checkLimiterRemoval`
    - If `_limiterRemovedToday` is true, return immediately (idempotence guard)
    - Call `PhysicalFoundation.isLimiterRemoved(_questProgress)`; if true: set `_limiterRemovedToday=true`, award 5 stat points to `_availablePoints`, set `_overloadTitleAwarded=true` on first trigger, persist both flags to `monarchState`, `notifyListeners()`
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 9.6_

  - [x] 3.19 Write property test for Limiter Removal threshold (Property 17)
    - **Property 17: Limiter Removal threshold**
    - **Validates: Requirements 7.1, 7.2**
    - Generate random progress values all >= 200% of each target; call `checkLimiterRemoval()`; assert `limiterRemovedToday=true` and `availablePoints` increased by 5

  - [x] 3.20 Write property test for Limiter Removal idempotence (Property 18)
    - **Property 18: Limiter Removal idempotence per day**
    - **Validates: Requirements 7.4, 9.6**
    - Generate random repeat count >= 2; call `checkLimiterRemoval()` that many times with 200%+ progress; assert stat points awarded exactly once and `limiterRemovedToday` remains true

  - [x] 3.21 Implement `recordDayCleared` (streak extension)
    - Increment `_streakDays`, update `_bestStreak` if needed, persist to settings, `notifyListeners()`
    - _Requirements: 3.3_

- [ ] 4. CoreEngine — Midnight Judgement
  - [x] 4.1 Add `runMidnightJudgement(PlayerProvider player)` to `CoreEngine`
    - Compute `player.physicalCompletionPct`
    - If `< 1.0`: call `player.activatePenaltyZone()`
    - If `>= 1.0`: call `player.recordDayCleared()`
    - Call `player.resetPhysicalProgress()`
    - Call `player.lockMandatoryQuests()`
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 4.2 Write property test for Midnight Judgement — penalty activation (Property 6)
    - **Property 6: Midnight Judgement — penalty activation**
    - **Validates: Requirements 3.1, 3.2**
    - Generate random progress state where `physicalCompletionPct < 1.0`; call `runMidnightJudgement`; assert `player.inPenaltyZone == true`

  - [x] 4.3 Write property test for Midnight Judgement — streak extension (Property 7)
    - **Property 7: Midnight Judgement — streak extension**
    - **Validates: Requirements 3.3**
    - Generate random progress state where `physicalCompletionPct >= 1.0`; call `runMidnightJudgement`; assert `player.streakDays` incremented by exactly 1

  - [x] 4.4 Write property test for Midnight Judgement — progress reset (Property 8)
    - **Property 8: Midnight Judgement — progress reset**
    - **Validates: Requirements 3.4**
    - Generate any combination of progress values; call `runMidnightJudgement`; assert all four sub-task values equal 0

- [x] 5. Checkpoint — Ensure all data layer and logic tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Holographic UI theme additions
  - [x] 6.1 Add Monarch color constants to `AppColors`
    - Add `monarchBackground = Color(0xFF000000)`, `penaltyBackground = Color(0xFF1A0000)`, `cyanGlow = Color(0xFF00FFFF)`, `cyanGlowDim = Color(0x4400FFFF)`
    - _Requirements: 8.1, 8.2, 8.6_

  - [x] 6.2 Create `lib/ui/theme/glow_decorations.dart` with `glowCardDecoration` helper
    - Implement `BoxDecoration glowCardDecoration({bool penalty = false})` with cyan border (width 1.2), `blurRadius: 15.0`, `spreadRadius: 1`, black fill
    - _Requirements: 8.2_

  - [x] 6.3 Create `lib/ui/widgets/quest_cleared_overlay.dart`
    - Full-screen overlay widget with `TweenAnimationBuilder` fade-in/out
    - Display "QUEST CLEARED.\nREWARDS DISTRIBUTED." in bold italic high-contrast sans-serif
    - Auto-dismiss after 2.5 seconds via `Future.delayed`
    - _Requirements: 8.3, 8.4_

  - [x] 6.4 Create `lib/ui/widgets/limiter_removed_overlay.dart`
    - Full-screen overlay widget displaying "LIMITER REMOVED" with cyan glow effect
    - Auto-dismiss after 3 seconds
    - _Requirements: 7.5, 8.2_

- [ ] 7. PenaltyZoneScreen implementation
  - [x] 7.1 Create `lib/penalty_zone_screen.dart`
    - `StatefulWidget` with background `Color(0xFF1A0000)`
    - Accept `VoidCallback onExpired` parameter
    - Use `StreamBuilder` on `Stream.periodic(Duration(seconds: 1))` to update countdown
    - Compute remaining: `Duration(hours: 4) - DateTime.now().difference(player.penaltyActivatedAt!)`
    - When remaining <= Duration.zero: call `onExpired()`
    - Display Survival_Timer as HH:MM:SS zero-padded string
    - Disable all navigation (no back button, no nav bar)
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6_

  - [x] 7.2 Write property test for Penalty Zone survival timer format (Property 9)
    - **Property 9: Penalty Zone survival timer format**
    - **Validates: Requirements 4.4**
    - Generate random seconds in [0, 14400]; call the timer format function; assert output matches regex `^\d{2}:\d{2}:\d{2}$`

  - [x] 7.3 Integrate `PenaltyZoneScreen` into `Dashboard` as a `Stack` overlay
    - In `Dashboard.build()`, add `Consumer<PlayerProvider>` inside the `Stack`
    - When `player.inPenaltyZone == true`, render `Positioned.fill(child: PenaltyZoneScreen(onExpired: () => player.deactivatePenaltyZone()))`
    - Use `IgnorePointer(ignoring: false)` to block all underlying taps
    - _Requirements: 4.1, 4.3_

- [x] 8. StatusScreen overhaul — Physical Foundation
  - [x] 8.1 Replace `StatusScreen` body with Physical Foundation quest card
    - Remove `DynamicEngine` dependency; replace with `Consumer<PlayerProvider>`
    - Define `static const List<_PhysSubTask> _subTasks` with the four hard-coded entries (Push-ups/100, Sit-ups/100, Squats/100, Running/10)
    - Render quest card titled "Daily Quest: Preparation for the Weak" using `glowCardDecoration`
    - _Requirements: 1.1, 1.2, 1.4_

  - [x] 8.2 Implement per-sub-task numeric input rows
    - Each sub-task renders a `TextFormField` with `keyboardType: TextInputType.number`
    - On `onChanged`: parse int, clamp negative to 0, call `player.logPhysicalProgress(key, value)`
    - Display current progress value and target (e.g., "42 / 100")
    - _Requirements: 1.3, 1.5_

  - [x] 8.3 Display aggregate completion percentage and STR/INT/PER stats
    - Show `physicalCompletionPct * 100` formatted as "XX.X%" below the sub-task list
    - Display STR, INT, PER values from `player.str`, `player.intStat`, `player.per`
    - Display both `lifetimeXP` (`player.totalXP`) and `walletXP` (`player.walletXP`)
    - _Requirements: 1.6, 5.7, 6.5_

  - [x] 8.4 Wire `QuestClearedOverlay` and `LimiterRemovedOverlay` into StatusScreen
    - Show `LimiterRemovedOverlay` when `player.limiterRemovedToday` transitions to true (use `didUpdateWidget` or a listener)
    - Show `QuestClearedOverlay` when physical completion reaches 100%
    - _Requirements: 7.5, 8.4_

- [x] 9. QuestsScreen overhaul — Input Mode / Locked state machine
  - [x] 9.1 Replace `QuestsScreen` with new Input Mode / Locked implementation
    - Remove `CoreEngine` / `CoreQuest` dependency from this screen
    - Add `TextEditingController` for cognitive duration and technical task inputs
    - Render two quest slots: Cognitive_Quest (Deep Work) and Technical_Quest (Skill Calibration)
    - _Requirements: 2.1_

  - [x] 9.2 Implement Input Mode rendering (unlocked state)
    - When `!player.cognitiveLocked`: render `TextFormField` for duration in minutes with validator [1, 480]
    - When `!player.technicalLocked`: render `TextFormField` for task description
    - On submit: call `player.setPendingCognitiveQuest(mins)` / `player.setPendingTechnicalQuest(task)` only if validation passes
    - Display inline validation error below field for out-of-range duration
    - _Requirements: 2.2, 2.3, 2.7_

  - [x] 9.3 Write property test for quest input validation (Property 4)
    - **Property 4: Quest input validation**
    - **Validates: Requirements 2.7**
    - Generate random int outside [1, 480]; attempt `setPendingCognitiveQuest`; assert validation error shown and `monarchState` not updated

  - [x] 9.4 Implement Locked state rendering
    - When `player.cognitiveLocked`: render read-only display of `lockedCognitiveDurationMinutes` with no edit controls
    - When `player.technicalLocked`: render read-only display of `lockedTechnicalTask` with no edit controls
    - When completed: render completion indicator (checkmark / "CLEARED" badge)
    - _Requirements: 2.4, 2.5, 2.6_

  - [x] 9.5 Add pulsing badge animation to quest info badges
    - Wrap quest info badges in `TweenAnimationBuilder<double>` cycling opacity between 0.6 and 1.0 over 900ms
    - Use `onEnd` callback to reverse direction for continuous pulse
    - _Requirements: 8.5_

  - [x] 9.6 Display Lifetime XP and Wallet XP on QuestsScreen header
    - Show both XP values in the screen header or a stats row
    - _Requirements: 5.7_

  - [x] 9.7 Wire `QuestClearedOverlay` for cognitive and technical quest completion
    - Show overlay when `completeCognitiveQuest()` or `completeTechnicalQuest()` is called
    - _Requirements: 8.4_

- [x] 10. Checkpoint — Ensure all UI tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 11. Integration tests
  - [x] 11.1 Write integration test: cold start with active, unexpired Penalty Zone
    - Seed `monarchState` with `inPenaltyZone=true` and `penaltyActivatedAt` = 1 hour ago
    - Launch app; assert `PenaltyZoneScreen` is shown and Survival_Timer displays ~3h remaining
    - _Requirements: 4.7, 4.8, 9.2, 9.5_

  - [x] 11.2 Write integration test: cold start with expired Penalty Zone
    - Seed `monarchState` with `inPenaltyZone=true` and `penaltyActivatedAt` = 5 hours ago
    - Launch app; assert Dashboard is shown (not PenaltyZoneScreen)
    - _Requirements: 4.6, 4.8_

  - [x] 11.3 Write integration test: full Midnight Judgement cycle
    - Set physical progress to < 100%; call `runMidnightJudgement`; assert `inPenaltyZone=true`, all progress reset to 0, quests locked
    - Set physical progress to >= 100%; call `runMidnightJudgement`; assert `streakDays` incremented, `inPenaltyZone=false`, all progress reset to 0
    - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 11.4 Write integration test: Limiter Removal full flow
    - Set all sub-task progress to >= 200% of targets; call `checkLimiterRemoval()`
    - Assert `availablePoints` increased by 5, `overloadTitleAwarded=true`, `limiterRemovedToday=true`
    - Call `checkLimiterRemoval()` again; assert `availablePoints` did not increase again
    - _Requirements: 7.1, 7.2, 7.3, 7.4_

- [x] 12. Final checkpoint — Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties (Properties 1–19 from design.md)
- Unit tests validate specific examples and edge cases
- The `fast_check` Dart package is used for property-based tests (minimum 100 iterations each)
