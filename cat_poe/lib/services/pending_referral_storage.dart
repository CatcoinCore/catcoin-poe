import 'package:shared_preferences/shared_preferences.dart';

/// Persists a referral code from invite links so it survives splash, login, and
/// navigation until signup succeeds or the user logs into an existing account.
class PendingReferralStorage {
  static const _key = 'pending_invite_referral_code_v1';

  static String _normalize(String code) =>
      code.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  static Future<void> save(String code) async {
    final normalized = _normalize(code);
    if (normalized.isEmpty) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, normalized);
  }

  static Future<String?> load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    return _normalize(raw);
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
  }
}
