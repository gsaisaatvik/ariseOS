import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'player_provider.dart';
import 'ui/widgets/widgets.dart';
import 'ui/theme/app_text_styles.dart';

class SkillsScreen extends StatelessWidget {
  const SkillsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = Provider.of<PlayerProvider>(context);

    // XP Bar Calculation
    int currentLevel = player.level;
    int nextLevelThreshold = (currentLevel + 1) * (currentLevel + 1);
    double progress =
        (player.totalXP.toDouble() / nextLevelThreshold.toDouble()).clamp(0.0, 1.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          HolographicPanel(
            header: const SystemHeaderBar(label: 'STATUS'),
            emphasize: true,
            child: _buildProfileSection(player, progress, nextLevelThreshold),
          ),
          HolographicPanel(
            header: const SystemHeaderBar(label: 'ATTRIBUTES'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (player.availablePoints > 0)
                  Text(
                    "Points available: ${player.availablePoints}",
                    style: AppTextStyles.bodySecondary,
                  ),
                const SizedBox(height: 16),
                _buildAttributeGrid(context, player),
              ],
            ),
          ),
          HolographicPanel(
            header: const SystemHeaderBar(label: 'ACTIVE ABILITIES'),
            child: _buildAbilitiesList(player),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(
      PlayerProvider player, double progress, int nextThreshold) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.3),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    "RANK",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1),
                  ),
                  Text(
                    player.rank,
                    style: const TextStyle(
                      color: Colors.purpleAccent,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "LEVEL",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, letterSpacing: 1),
                  ),
                  Text(
                    player.level.toString(),
                    style: const TextStyle(
                      color: Color(0xFF00FFFF),
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "XP PROGRESS",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              Text(
                "${player.totalXP} / $nextThreshold",
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress Bar
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FFFF),
                      borderRadius: BorderRadius.circular(3),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttributeGrid(BuildContext context, PlayerProvider player) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatItem("STRENGTH", player.strength, player.availablePoints > 0, () => player.increaseStrength())),
            const SizedBox(width: 12),
            Expanded(child: _buildStatItem("FOCUS", player.focus, player.availablePoints > 0, () => player.increaseFocus())),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatItem("DISCIPLINE", player.discipline, player.availablePoints > 0, () => player.increaseDiscipline())),
            const SizedBox(width: 12),
            Expanded(child: _buildStatItem("INTELLIGENCE", player.intelligence, player.availablePoints > 0, () => player.increaseIntelligence())),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int value, bool canIncrease, VoidCallback onIncrease) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[900]!.withOpacity(0.5),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: const TextStyle(color: Color(0xFF00FFFF), fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          if (canIncrease)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: GestureDetector(
                onTap: onIncrease,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF00FFFF).withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF00FFFF), size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAbilitiesList(PlayerProvider player) {
    final List<Widget> abilities = [];

    if (player.flowUnlocked) {
      abilities.add(_buildAbilityTile("FLOW STATE", "Double XP - Next Deep Work", player.flowUsedToday, "DAILY", () => player.activateFlow()));
    }
    if (player.enduranceUnlocked) {
      abilities.add(_buildAbilityTile("ENDURANCE", "+5 XP - Next Strength", player.enduranceUsedToday, "DAILY", () => player.activateEndurance()));
    }
    if (player.insightUnlocked) {
      abilities.add(_buildAbilityTile("INSIGHT", "+5 XP - Next Dungeon", player.insightUsedToday, "DAILY", () => player.activateInsight()));
    }
    if (player.ironUnlocked) {
      abilities.add(_buildAbilityTile("IRON RESOLVE", "Block next penalty", player.ironUsedThisWeek, "WEEKLY", () => player.activateIron()));
    }

    if (abilities.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
        child: const Text(
          "NO ABILITIES UNLOCKED\nREACH LEVEL 10 STATS TO AWAKEN",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: 1),
        ),
      );
    }

    return Column(children: abilities);
  }

  Widget _buildAbilityTile(String name, String desc, bool isUsed, String cooldown, VoidCallback onActivate) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUsed ? Colors.black : Colors.grey[900]!.withOpacity(0.4),
        border: Border.all(color: isUsed ? Colors.white10 : Colors.purpleAccent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: TextStyle(color: isUsed ? Colors.white24 : Colors.purpleAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)),
                      child: Text(cooldown, style: const TextStyle(color: Colors.white38, fontSize: 8)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: isUsed ? Colors.white10 : Colors.white54, fontSize: 11)),
              ],
            ),
          ),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: isUsed ? null : onActivate,
              style: ElevatedButton.styleFrom(
                backgroundColor: isUsed ? Colors.transparent : Colors.purpleAccent.withOpacity(0.2),
                foregroundColor: Colors.purpleAccent,
                side: BorderSide(color: isUsed ? Colors.white10 : Colors.purpleAccent.withOpacity(0.5)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
              ),
              child: Text(isUsed ? "USED" : "ACTIVATE", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
