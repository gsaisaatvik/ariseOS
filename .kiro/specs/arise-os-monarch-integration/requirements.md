# Requirements Document

## Introduction

ARISE OS Monarch Integration is the next evolution of the ARISE OS Flutter app. The system transitions from a general productivity tool into a sentient life-management system inspired by the Solo Leveling universe. It introduces a Dual-Mandatory Architecture with three growth pillars: a hard-coded Physical Foundation (Status Screen), and two user-configurable cognitive/technical quests (Quests Screen). The feature adds a Penalty Zone lockout for physical quest failure, a dual XP economy (Lifetime vs. Wallet), a Limiter Removal mechanic for 200% physical overload, and a full holographic UI aesthetic overhaul.

The existing codebase uses `PlayerProvider` (ChangeNotifier) for player state, `HiveService` for persistence, `CoreEngine` for quest logic, `AdaptiveDirectiveEngine` for directive tracking, and `RankEngine` for rank computation. This feature refactors and extends all of these systems.

---

## Glossary

- **System**: The ARISE OS application as a whole.
- **Hunter**: The user of the application.
- **Physical_Foundation**: The hard-coded daily physical quest consisting of 100 Push-ups, 100 Sit-ups, 100 Squats, and 10 km Running.
- **Status_Screen**: The screen displaying the Physical_Foundation quest and player stats. Its quest content is immutable.
- **Quests_Screen**: The screen where the Hunter configures tomorrow's Cognitive_Quest and Technical_Quest targets.
- **Cognitive_Quest**: The daily Deep Work focused session quest (Pillar 2), user-configurable in duration.
- **Technical_Quest**: The daily Skill Calibration quest for ReactJS, DSA, or IIT Madras coursework (Pillar 3), user-configurable in task or duration.
- **Locked_Mandatory_Quest**: A Cognitive_Quest or Technical_Quest that has been committed at midnight and cannot be edited for the current day.
- **Midnight_Judgement**: The automated evaluation that occurs at 00:00 local time each day.
- **Penalty_Zone**: A full-screen lockout state activated when the Physical_Foundation is not 100% complete at Midnight_Judgement.
- **Survival_Timer**: A countdown timer displayed exclusively during the Penalty_Zone, showing the remaining lockout duration.
- **Lifetime_XP**: Cumulative XP that never decreases, used for rank progression.
- **Wallet_XP**: Spendable XP currency used for Potions and Titles; can go negative.
- **STR**: The Strength stat, bound to Physical_Foundation performance.
- **INT**: The Intelligence stat, bound to Technical_Quest (Skill Calibration) performance.
- **PER**: The Perception stat, bound to Cognitive_Quest (Deep Work) performance.
- **Limiter_Removal**: The mechanic triggered when the Hunter completes 200% of the Physical_Foundation targets.
- **Secret_Quest_Event**: A special reward event triggered by Limiter_Removal.
- **Overload_Title**: A permanent title awarded upon first Limiter_Removal completion.
- **PlayerProvider**: The existing Flutter ChangeNotifier class managing all player state.
- **CoreEngine**: The existing engine managing core quest lifecycle.
- **HiveService**: The existing Hive-based local persistence service.
- **AdaptiveDirectiveEngine**: The existing engine tracking per-directive performance metrics.

---

## Requirements

### Requirement 1: Physical Foundation — Hard-Coded Status Screen Quest

**User Story:** As a Hunter, I want the Status Screen to always display the fixed "Daily Quest: Preparation for the Weak" with its exact targets, so that the System's Will is immutable and cannot be altered.

#### Acceptance Criteria

1. THE Status_Screen SHALL display a quest card titled "Daily Quest: Preparation for the Weak" as its primary content.
2. THE Status_Screen SHALL display the following four fixed sub-tasks within the quest card: 100 Push-ups, 100 Sit-ups, 100 Squats, and 10 km Running.
3. THE Status_Screen SHALL render each sub-task with an individual numeric progress input allowing the Hunter to log a count or distance value.
4. THE System SHALL prevent any user action from modifying, removing, or reordering the four Physical_Foundation sub-tasks.
5. WHEN the Hunter logs progress for a Physical_Foundation sub-task, THE Status_Screen SHALL update the displayed progress value immediately without requiring a page reload.
6. THE Status_Screen SHALL display an aggregate Physical_Foundation completion percentage calculated as the mean completion ratio across all four sub-tasks.

---

### Requirement 2: Quests Screen — Configurable Cognitive and Technical Quests

**User Story:** As a Hunter, I want to define tomorrow's Deep Work duration and Skill Calibration task on the Quests Screen, so that I can set my own path to growth within the System's framework.

#### Acceptance Criteria

1. THE Quests_Screen SHALL display two configurable quest slots: one for Cognitive_Quest (Deep Work) and one for Technical_Quest (Skill Calibration).
2. WHEN the current day's Locked_Mandatory_Quests have not yet been set for tomorrow, THE Quests_Screen SHALL render both quest slots in Input Mode, allowing the Hunter to enter a duration in minutes for Cognitive_Quest and a task description or duration for Technical_Quest.
3. THE System SHALL persist the Hunter's configured Cognitive_Quest and Technical_Quest targets to HiveService before midnight of the configuration day.
4. WHEN the local clock reaches 00:00, THE System SHALL transition both configured quests to Locked_Mandatory_Quest status for the current day.
5. WHILE a quest is in Locked_Mandatory_Quest status, THE Quests_Screen SHALL display the quest as read-only and SHALL NOT render any edit controls for that quest.
6. WHEN a Locked_Mandatory_Quest is completed by the Hunter, THE Quests_Screen SHALL display a completion indicator for that quest.
7. IF the Hunter attempts to submit a Cognitive_Quest duration of less than 1 minute or greater than 480 minutes, THEN THE Quests_Screen SHALL display a validation error and SHALL NOT persist the invalid value.

---

### Requirement 3: Midnight Judgement — Daily Evaluation

**User Story:** As a Hunter, I want the System to evaluate my Physical_Foundation completion at midnight, so that failure has real consequences and success is rewarded.

#### Acceptance Criteria

1. WHEN the local clock reaches 00:00, THE System SHALL evaluate the Physical_Foundation completion percentage for the ending day.
2. IF the Physical_Foundation completion percentage is less than 100% at Midnight_Judgement, THEN THE System SHALL activate the Penalty_Zone for the Hunter.
3. WHEN the Physical_Foundation completion percentage is 100% or greater at Midnight_Judgement, THE System SHALL record the day as cleared and extend the Hunter's streak.
4. WHEN Midnight_Judgement completes, THE System SHALL reset all Physical_Foundation sub-task progress values to zero for the new day.
5. WHEN Midnight_Judgement completes, THE System SHALL transition the Hunter's configured Cognitive_Quest and Technical_Quest into Locked_Mandatory_Quest status for the new day.

---

### Requirement 4: Penalty Zone — Full-Screen Lockout

**User Story:** As a Hunter, I want the Penalty Zone to consume the entire app when I fail the Physical Foundation, so that failure is a visceral, unavoidable consequence.

#### Acceptance Criteria

1. WHILE the Hunter's `inPenaltyZone` state is true, THE System SHALL render the Penalty_Zone screen as the full-screen foreground view, obscuring all other app content.
2. THE Penalty_Zone screen SHALL use a background color of #1A0000 (Deep Red).
3. WHILE the Penalty_Zone is active, THE System SHALL disable navigation to all screens except the Penalty_Zone itself.
4. THE Penalty_Zone screen SHALL display a Survival_Timer showing the remaining lockout duration as a countdown in HH:MM:SS format.
5. THE Penalty_Zone SHALL enforce a lockout duration of exactly 4 hours from the moment of activation.
6. WHEN the Survival_Timer reaches 00:00:00, THE System SHALL deactivate the Penalty_Zone and restore full app navigation.
7. THE System SHALL persist the Penalty_Zone activation timestamp to HiveService so that the lockout survives app restarts within the 4-hour window.
8. IF the Hunter restarts the app while the Penalty_Zone is active and the 4-hour window has not elapsed, THEN THE System SHALL re-display the Penalty_Zone with the Survival_Timer reflecting the remaining duration.

---

### Requirement 5: Dual XP Economy

**User Story:** As a Hunter, I want my XP to be split into Lifetime XP for rank progression and Wallet XP for spending, so that I can track long-term growth separately from spendable rewards.

#### Acceptance Criteria

1. THE System SHALL maintain two separate XP values for the Hunter: Lifetime_XP and Wallet_XP.
2. THE System SHALL use the formula `Level = floor(sqrt(LifetimeXP) / 10) + 1` to compute the Hunter's level from Lifetime_XP.
3. WHEN the Hunter earns XP from completing a quest, THE System SHALL add the earned amount to both Lifetime_XP and Wallet_XP simultaneously.
4. THE System SHALL never decrement Lifetime_XP for any reason, including penalties.
5. WHEN a penalty is applied, THE System SHALL deduct the penalty amount from Wallet_XP only.
6. THE System SHALL allow Wallet_XP to reach a minimum floor of -500 and SHALL NOT decrement Wallet_XP below -500.
7. THE Quests_Screen and Status_Screen SHALL display both Lifetime_XP and Wallet_XP values to the Hunter.

---

### Requirement 6: Stat Binding — STR, INT, PER

**User Story:** As a Hunter, I want my STR stat to reflect physical performance, INT to reflect skill work, and PER to reflect deep work, so that my stats are a true measure of my growth pillars.

#### Acceptance Criteria

1. WHEN the Hunter completes a Physical_Foundation session, THE PlayerProvider SHALL increment the STR stat by the configured reward amount.
2. WHEN the Hunter completes a Technical_Quest (Skill Calibration) session, THE PlayerProvider SHALL increment the INT stat by the configured reward amount.
3. WHEN the Hunter completes a Cognitive_Quest (Deep Work) session, THE PlayerProvider SHALL increment the PER stat by the configured reward amount.
4. THE PlayerProvider SHALL persist all stat changes to HiveService immediately after each increment.
5. THE Status_Screen SHALL display the current STR, INT, and PER values for the Hunter.

---

### Requirement 7: Limiter Removal — 200% Overload

**User Story:** As a Hunter, I want to trigger a Secret Quest Event by completing 200% of the Physical Foundation targets, so that extraordinary effort is rewarded with permanent power.

#### Acceptance Criteria

1. WHEN the Hunter logs Physical_Foundation progress such that every sub-task reaches or exceeds 200% of its target value, THE System SHALL trigger a Secret_Quest_Event.
2. WHEN a Secret_Quest_Event is triggered, THE System SHALL award the Hunter 5 Stat Points to the available allocation pool.
3. WHEN a Secret_Quest_Event is triggered for the first time, THE System SHALL permanently assign the Overload_Title to the Hunter's profile.
4. THE System SHALL trigger the Secret_Quest_Event at most once per day, regardless of how many times the Hunter exceeds 200% of the targets.
5. WHEN a Secret_Quest_Event is triggered, THE System SHALL display a "LIMITER REMOVED" system message overlay to the Hunter.

---

### Requirement 8: Holographic UI Aesthetic

**User Story:** As a Hunter, I want the app to look and feel like a holographic system interface, so that the experience is immersive and reinforces the Solo Leveling theme.

#### Acceptance Criteria

1. THE System SHALL use #000000 (True Black) as the background color for all primary screens.
2. THE System SHALL render card borders using cyan (#00FFFF) with a `blurRadius` of 15.0 to simulate glowing light.
3. THE System SHALL use bold, italicized, high-contrast sans-serif typography for all primary headings and quest titles.
4. WHEN a quest is completed, THE System SHALL display a full-screen "QUEST CLEARED. REWARDS DISTRIBUTED." system message overlay using a TweenAnimationBuilder fade animation.
5. THE Quests_Screen quest info badges SHALL pulse using a TweenAnimationBuilder repeating opacity animation between 0.6 and 1.0 opacity.
6. THE Penalty_Zone screen SHALL use #1A0000 (Deep Red) as its background color, distinct from the standard #000000 background.

---

### Requirement 9: Persistence and State Recovery

**User Story:** As a Hunter, I want all my progress, quest states, and penalty status to survive app restarts, so that the System's memory is permanent.

#### Acceptance Criteria

1. THE System SHALL persist Physical_Foundation sub-task progress values to HiveService after each Hunter input.
2. THE System SHALL persist the Penalty_Zone activation timestamp and `inPenaltyZone` flag to HiveService when the Penalty_Zone is activated.
3. THE System SHALL persist Cognitive_Quest and Technical_Quest configuration targets to HiveService when the Hunter submits them.
4. THE System SHALL persist the Locked_Mandatory_Quest status for Cognitive_Quest and Technical_Quest to HiveService at Midnight_Judgement.
5. WHEN the app is launched, THE System SHALL read all persisted state from HiveService and restore the UI to the correct state before rendering any screen.
6. THE System SHALL persist the Secret_Quest_Event trigger flag per day to HiveService to prevent duplicate Secret_Quest_Event awards across app restarts.
