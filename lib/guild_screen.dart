import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'player_provider.dart';
import 'system/guild_service.dart';
import 'ui/widgets/widgets.dart';
import 'ui/theme/app_text_styles.dart';
import 'widgets/system_overlay.dart';

class GuildScreen extends StatefulWidget {
  const GuildScreen({super.key});

  @override
  State<GuildScreen> createState() => _GuildScreenState();
}

class _GuildScreenState extends State<GuildScreen> {
  final _createName = TextEditingController();
  final _joinId = TextEditingController();
  final _joinName = TextEditingController();
  String _domain = 'Fitness';

  @override
  void dispose() {
    _createName.dispose();
    _joinId.dispose();
    _joinName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerProvider>();
    GuildService.upsertSelf(player);

    final guildId = GuildService.currentGuildId;
    final guildName = GuildService.currentGuildName;
    final guildDomain = GuildService.currentGuildDomain;
    final members = GuildService.leaderboard();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(child: SystemHeaderBar(label: 'GUILD TERMINAL')),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (guildId == null)
                HolographicPanel(
                  header: const SystemHeaderBar(label: 'CREATE / JOIN'),
                  emphasize: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guilds are stored locally (Phase 7). Leaderboards are future-ready.',
                        style: AppTextStyles.bodySecondary,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _domain,
                        items: GuildService.allowedDomains
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(d),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _domain = v);
                        },
                        dropdownColor: const Color(0xFF050716),
                        decoration: InputDecoration(
                          labelText: 'Domain',
                          labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _createName,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Create guild name',
                          labelStyle:
                              TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: PrimaryActionButton(
                          label: 'CREATE GUILD',
                          onPressed: () async {
                            final id =
                                await GuildService.createGuild(
                                  name: _createName.text,
                                  domain: _domain,
                                );
                            if (!context.mounted) return;
                            setState(() {});
                            SystemOverlay.show(
                              context,
                              title: 'GUILD CREATED',
                              message: 'Guild ID: $id',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: _joinId,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Join guild ID',
                          labelStyle:
                              TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _domain,
                        items: GuildService.allowedDomains
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(d),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _domain = v);
                        },
                        dropdownColor: const Color(0xFF050716),
                        decoration: InputDecoration(
                          labelText: 'Domain',
                          labelStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _joinName,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Guild name (optional)',
                          labelStyle:
                              TextStyle(color: Colors.white.withValues(alpha: 0.55)),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: SecondaryActionButton(
                          label: 'JOIN',
                          onPressed: () async {
                            await GuildService.joinGuild(
                              id: _joinId.text,
                              domain: _domain,
                              name: _joinName.text,
                            );
                            if (!context.mounted) return;
                            setState(() {});
                            SystemOverlay.show(
                              context,
                              title: 'GUILD LINKED',
                              message: 'Membership established.',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                HolographicPanel(
                  header: const SystemHeaderBar(label: 'GUILD STATUS'),
                  emphasize: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (guildName ?? 'GUILD').toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'DOMAIN: ${(guildDomain ?? '').toUpperCase()}  •  ID: $guildId',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: SecondaryActionButton(
                          label: 'LEAVE GUILD',
                          onPressed: () {
                            GuildService.leaveGuild();
                            setState(() {});
                            SystemOverlay.show(
                              context,
                              title: 'GUILD',
                              message: 'Membership removed.',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                HolographicPanel(
                  header: const SystemHeaderBar(label: 'LEADERBOARD'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (members.isEmpty)
                        Text('No members recorded yet.', style: AppTextStyles.bodySecondary)
                      else
                        ...members.asMap().entries.map((entry) {
                          final idx = entry.key + 1;
                          final m = entry.value;
                          return _leaderRow(
                            idx,
                            (m['name'] as String?) ?? 'UNKNOWN',
                            (m['totalXP'] as num?)?.toInt() ?? 0,
                            (m['streakDays'] as num?)?.toInt() ?? 0,
                            (m['discipline'] as num?)?.toInt() ?? 0,
                          );
                        }),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: SecondaryActionButton(
                    label: 'BACK',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _leaderRow(int rank, String name, int xp, int streak, int discipline) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          _statChip('XP', xp),
          const SizedBox(width: 8),
          _statChip('STREAK', streak),
          const SizedBox(width: 8),
          _statChip('DISC', discipline),
        ],
      ),
    );
  }

  Widget _statChip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.7),
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

