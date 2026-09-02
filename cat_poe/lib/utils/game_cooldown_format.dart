/// Formats remaining cooldown for display (aligned with [GamesScreen] helpers).
/// Returns `null` if [until] is absent or already elapsed.
String? formatGameCooldownRemaining(DateTime? until) {
  if (until == null) return null;
  final diff = until.difference(DateTime.now());
  if (diff.isNegative) return null;
  final h = diff.inHours;
  final m = diff.inMinutes.remainder(60);
  final s = diff.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m ${s}s';
  return '${s}s';
}
