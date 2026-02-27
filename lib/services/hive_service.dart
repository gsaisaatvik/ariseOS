import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/subject.dart';
import '../models/dungeon.dart';
import '../models/core_quest.dart';
import '../models/dungeon_template.dart';

class HiveService {
  static const String subjectsBox = 'subjects';
  static const String settingsBox = 'settings';
  static const String dungeonsBox = 'dungeons';
  static const String coreQuestsBox = 'core_quests';
  static const String dungeonTemplatesBox = 'dungeon_templates';
  static const String dynamicStateBox = 'dynamic_state';

  static Future<void> init() async {
    await Hive.initFlutter();

    /// 🔥 REGISTER ADAPTERS
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SubjectAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DungeonAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(CoreQuestAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(DungeonTemplateAdapter());
    }

    /// 🔥 OPEN BOXES
    final subjects =
        await Hive.openBox<Subject>(subjectsBox);

    await Hive.openBox(settingsBox);
    await Hive.openBox<Dungeon>(dungeonsBox);

    final coreQuests =
        await Hive.openBox<CoreQuest>(coreQuestsBox);

    final dungeonTemplates =
        await Hive.openBox<DungeonTemplate>(
            dungeonTemplatesBox);

    await Hive.openBox(dynamicStateBox);

    /// 🔥 SEED SUBJECTS
    if (subjects.isEmpty) {
      await subjects.addAll([
        Subject(
          id: 'fitness',
          name: 'Fitness Training',
          baseDifficulty: 1.0,
          scalingFactor: 0.2,
        ),
        Subject(
          id: 'leetcode',
          name: 'Solve 1 LeetCode',
          baseDifficulty: 1.2,
          scalingFactor: 0.25,
        ),
        Subject(
          id: 'reading',
          name: 'Read 10 Pages',
          baseDifficulty: 0.8,
          scalingFactor: 0.15,
        ),
      ]);
    }

    /// 🔥 SEED CORE QUESTS
    if (coreQuests.isEmpty) {
      await coreQuests.addAll([
        CoreQuest(
          id: 'strength',
          name: 'Strength Training',
          date: DateTime.now(),
        ),
        CoreQuest(
          id: 'deep_work',
          name: '90 Min Deep Work',
          date: DateTime.now(),
        ),
        CoreQuest(
          id: 'dsa',
          name: '2 DSA Problems',
          date: DateTime.now(),
        ),
      ]);
    }

    /// 🔥 SEED DUNGEON TEMPLATES
    if (dungeonTemplates.isEmpty) {
      await dungeonTemplates.addAll([
        DungeonTemplate(
          id: 'dsa_foundation',
          name: 'DSA Foundation Forge',
          description:
              'Study 1 concept + implement + solve 2 easy problems',
          category: 'Career',
        ),
        DungeonTemplate(
          id: 'dsa_medium',
          name: 'DSA Medium Assault',
          description:
              'Solve 1 LeetCode Medium + write explanation',
          category: 'Career',
        ),
        DungeonTemplate(
          id: 'iitm_deep',
          name: 'IITM Deep Study Gate',
          description:
              '2 hour focused IITM study + written notes',
          category: 'Academic',
        ),
        DungeonTemplate(
          id: 'project_sprint',
          name: 'Project Build Sprint',
          description:
              'Implement 1 real feature + commit code',
          category: 'Career',
        ),
        DungeonTemplate(
          id: 'mock_interview',
          name: 'Mock Interview Arena',
          description:
              'Timed DSA question + explanation recording',
          category: 'Career',
        ),
        DungeonTemplate(
          id: 'endurance_raid',
          name: 'Endurance Raid',
          description:
              '5km run OR 40 min cardio session',
          category: 'Physical',
        ),
        DungeonTemplate(
          id: 'revision',
          name: 'Revision Consolidation',
          description:
              'Revise 3 topics + solve 5 questions',
          category: 'Academic',
        ),
      ]);
    }
  }

  /// 🔥 GETTERS

  static Box<Subject> get subjects =>
      Hive.box<Subject>(subjectsBox);

  static Box get settings =>
      Hive.box(settingsBox);

  static Box<Dungeon> get dungeons =>
      Hive.box<Dungeon>(dungeonsBox);

  static Box<CoreQuest> get coreQuests =>
      Hive.box<CoreQuest>(coreQuestsBox);

  static Box<DungeonTemplate> get dungeonTemplates =>
      Hive.box<DungeonTemplate>(dungeonTemplatesBox);

  static Box get dynamicState =>
      Hive.box(dynamicStateBox);
}