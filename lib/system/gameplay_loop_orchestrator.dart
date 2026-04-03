import '../engine/core_engine.dart';
import '../models/core_quest.dart';
import '../player_provider.dart';
import '../system/adaptive_directive_engine.dart';
import '../system/guild_service.dart';

class GameplayLoopOrchestrator {
  GameplayLoopOrchestrator._();

  /// Execute → Reward → Adapt → Compete (completion path).
  static Future<int> onDirectiveCompleted({
    required CoreEngine engine,
    required CoreQuest quest,
    required PlayerProvider player,
    required int minutes,
    required int baseXp,
  }) async {
    // Execute
    await engine.completeQuest(quest);

    // Reward (XP + HP + economy handled by PlayerProvider)
    final earned = player.addTimedXP(baseXp, minutes);

    // Adapt (metrics)
    AdaptiveDirectiveEngine.recordCompletion(
      directiveId: quest.id,
      completionMinutes: minutes,
    );

    // Compete (guild snapshot)
    GuildService.upsertSelf(player);

    return earned;
  }

  /// Execute → Penalty → Adapt → Compete (abort path).
  static int onDirectiveAborted({
    required PlayerProvider player,
    required String directiveId,
    required int elapsedSeconds,
  }) {
    // Adapt (metrics)
    AdaptiveDirectiveEngine.recordAbort(directiveId: directiveId);

    // Penalty (wallet + HP handled by PlayerProvider)
    int penaltyApplied = 0;
    if (elapsedSeconds >= 60) {
      penaltyApplied = player.applyDirectiveAbortPenalty();
    }

    // Compete (guild snapshot)
    GuildService.upsertSelf(player);

    return penaltyApplied;
  }
}

