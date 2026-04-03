import 'dart:math' as math;

import '../services/hive_service.dart';
import '../player_provider.dart';

class GuildService {
  GuildService._();

  static const String _kGuildId = 'guild_current_id';
  static const String _kGuildName = 'guild_current_name';
  static const String _kGuildDomain = 'guild_current_domain';

  static String? get currentGuildId {
    final v = HiveService.settings.get(_kGuildId, defaultValue: '') as String;
    return v.isEmpty ? null : v;
  }

  static String? get currentGuildName {
    final v = HiveService.settings.get(_kGuildName, defaultValue: '') as String;
    return v.isEmpty ? null : v;
  }

  static String? get currentGuildDomain {
    final v =
        HiveService.settings.get(_kGuildDomain, defaultValue: '') as String;
    return v.isEmpty ? null : v;
  }

  static const List<String> allowedDomains = [
    'Fitness',
    'Study',
    'GATE',
    'Coding',
  ];

  static String _guildBoxKey(String guildId) => 'guild_$guildId';

  static String _newGuildId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = math.Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  static Future<String> createGuild({
    required String name,
    required String domain,
  }) async {
    final id = _newGuildId();
    HiveService.settings.put(_kGuildId, id);
    HiveService.settings.put(_kGuildName, name.trim().isEmpty ? 'GUILD' : name.trim());
    HiveService.settings.put(_kGuildDomain, domain);

    final box = HiveService.dynamicState;
    box.put(_guildBoxKey(id), {
      'id': id,
      'name': HiveService.settings.get(_kGuildName),
      'domain': domain,
      'members': <Map<String, dynamic>>[],
    });
    return id;
  }

  static Future<void> joinGuild({
    required String id,
    required String domain,
    String? name,
  }) async {
    final cleaned = id.trim().toUpperCase();
    if (cleaned.isEmpty) return;

    HiveService.settings.put(_kGuildId, cleaned);
    HiveService.settings.put(_kGuildDomain, domain);
    if (name != null && name.trim().isNotEmpty) {
      HiveService.settings.put(_kGuildName, name.trim());
    }

    final box = HiveService.dynamicState;
    final key = _guildBoxKey(cleaned);
    if (!box.containsKey(key)) {
      box.put(key, {
        'id': cleaned,
        'name': name?.trim().isNotEmpty == true ? name!.trim() : 'GUILD',
        'domain': domain,
        'members': <Map<String, dynamic>>[],
      });
    }
  }

  static void leaveGuild() {
    HiveService.settings.put(_kGuildId, '');
    HiveService.settings.put(_kGuildName, '');
    HiveService.settings.put(_kGuildDomain, '');
  }

  static void upsertSelf(PlayerProvider player) {
    final id = currentGuildId;
    if (id == null) return;
    final box = HiveService.dynamicState;
    final key = _guildBoxKey(id);
    final data = box.get(key, defaultValue: null);
    if (data is! Map) return;

    final members = (data['members'] as List?)?.cast<Map>() ?? <Map>[];
    final now = DateTime.now().toUtc().toIso8601String();

    final entry = <String, dynamic>{
      'name': player.name,
      'totalXP': player.totalXP,
      'streakDays': player.streakDays,
      'discipline': player.discipline,
      'updatedAt': now,
    };

    final idx = members.indexWhere((m) => (m['name'] as String?) == player.name);
    if (idx >= 0) {
      members[idx] = entry;
    } else {
      members.add(entry);
    }

    data['members'] = members;
    box.put(key, data);
  }

  static List<Map<String, dynamic>> leaderboard() {
    final id = currentGuildId;
    if (id == null) return const [];
    final box = HiveService.dynamicState;
    final data = box.get(_guildBoxKey(id), defaultValue: null);
    if (data is! Map) return const [];
    final members = (data['members'] as List?)?.cast<Map>() ?? <Map>[];
    final list = members.map((m) => m.cast<String, dynamic>()).toList();
    list.sort((a, b) {
      final ax = (a['totalXP'] as num?)?.toInt() ?? 0;
      final bx = (b['totalXP'] as num?)?.toInt() ?? 0;
      return bx.compareTo(ax);
    });
    return list;
  }
}

