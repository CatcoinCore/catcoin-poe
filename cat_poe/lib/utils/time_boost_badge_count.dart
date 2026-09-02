import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/active_session.dart';
import '../models/admin_config.dart';
import '../models/time_boost_slot.dart';

ActiveSession? findBaseActiveSession(List<ActiveSession> sessions) {
  for (final s in sessions) {
    if (s.sessionType == 'BASE') return s;
  }
  return null;
}

/// Same as backend: `int((end_time - start_time).total_seconds() / 60)`.
int miningSessionDurationMinutes(DateTime start, DateTime end) {
  return end.toUtc().difference(start.toUtc()).inSeconds ~/ 60;
}

/// Parses admin "time extension slots" into hour values (same as [BoostersScreen]).
List<int> parseTimeExtensionSlotHours(AdminConfig? config) {
  List<int> extensionSlots = [2, 3, 4, 5, 6];
  if (config?.timeExtensionSlots != null) {
    try {
      final str = config!.timeExtensionSlots
          .replaceAll('[', '')
          .replaceAll(']', '')
          .replaceAll(' ', '');
      extensionSlots =
          str.split(',').map((s) => (int.parse(s) / 60).round()).toList();
    } catch (_) {}
  }
  return extensionSlots;
}

/// Server-backed time boosts from [ActiveSession.timeBoostSlots] (preferred).
List<TimeBoostSlot> timeBoostSlotsFromBaseSession(ActiveSession? base) {
  final slots = base?.timeBoostSlots;
  if (slots == null || slots.isEmpty) return [];
  return List<TimeBoostSlot>.from(slots);
}

/// Legacy: per-session time boost hours and active cooldowns (local prefs).
/// Used only when the API does not return [time_boost_slots] yet.
Future<({List<int> sessionHours, Map<int, DateTime> activeCooldowns})>
    loadTimeBoostSessionStateLegacy({
  required SharedPreferences prefs,
  required String sessionId,
  required AdminConfig? config,
  required String userId,
}) async {
  final extensionSlots = parseTimeExtensionSlotHours(config);
  final sessionKey = 'session_boosts_$sessionId';
  final savedBoostsStr = prefs.getStringList(sessionKey);

  List<int> sessionBoosts;
  if (savedBoostsStr != null && savedBoostsStr.isNotEmpty) {
    sessionBoosts = savedBoostsStr
        .map((e) => int.parse(e))
        .where((b) => extensionSlots.contains(b))
        .toList();
  } else {
    sessionBoosts = [];
  }

  if (sessionBoosts.length < 2) {
    final available = List<int>.from(extensionSlots)
      ..removeWhere((b) => sessionBoosts.contains(b));
    available.shuffle(Random());

    while (sessionBoosts.length < 2 && available.isNotEmpty) {
      sessionBoosts.add(available.removeLast());
    }

    await prefs.setStringList(
        sessionKey, sessionBoosts.map((e) => e.toString()).toList());
  }

  final activeCooldowns = <int, DateTime>{};
  final now = DateTime.now();
  for (final hours in sessionBoosts) {
    final cooldownKey = 'cooldown_${userId}_$hours';
    final cooldownStr = prefs.getString(cooldownKey);
    if (cooldownStr != null) {
      final cooldownEnd = DateTime.parse(cooldownStr);
      if (cooldownEnd.isAfter(now)) {
        activeCooldowns[hours] = cooldownEnd;
      } else {
        await prefs.remove(cooldownKey);
      }
    }
  }

  return (sessionHours: sessionBoosts, activeCooldowns: activeCooldowns);
}

/// Resolves [TimeBoostSlot] list: API first, else legacy prefs converted to slots.
Future<List<TimeBoostSlot>> resolveTimeBoostSlots({
  required ActiveSession? baseSession,
  required SharedPreferences prefs,
  required AdminConfig? config,
  required String userId,
}) async {
  final fromApi = timeBoostSlotsFromBaseSession(baseSession);
  if (fromApi.isNotEmpty) return fromApi;
  if (baseSession == null) return [];

  final legacy = await loadTimeBoostSessionStateLegacy(
    prefs: prefs,
    sessionId: baseSession.id,
    config: config,
    userId: userId,
  );
  if (legacy.sessionHours.isEmpty) return [];

  return [
    for (final h in legacy.sessionHours)
      TimeBoostSlot(
        hours: h,
        cooldownUntil: legacy.activeCooldowns[h],
        active: true,
      ),
  ];
}

/// Counts time boosts the user can still apply (server [active] flag, cooldown, session cap).
int countAvailableTimeBoosts({
  required List<TimeBoostSlot> slots,
  required int currentDurationMinutes,
  required int maxDurationMinutes,
}) {
  if (currentDurationMinutes >= maxDurationMinutes) return 0;
  final now = DateTime.now().toUtc();
  var n = 0;
  for (final s in slots) {
    if (!s.active) continue;
    final cd = s.cooldownUntil;
    if (cd != null && cd.isAfter(now)) continue;
    n++;
  }
  return n;
}
