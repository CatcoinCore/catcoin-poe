class ReferralInfo {
  final String referralId;
  final String referralUsername;
  final String? referralDisplayName;
  final bool isActive;
  final DateTime lastActiveAt;
  final bool canBoost;
  final String? activeBoostSessionId;

  ReferralInfo({
    required this.referralId,
    required this.referralUsername,
    this.referralDisplayName,
    required this.isActive,
    required this.lastActiveAt,
    required this.canBoost,
    this.activeBoostSessionId,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    String lastActiveStr = json['last_active_at'] as String;
    if (!lastActiveStr.endsWith('Z') && !lastActiveStr.contains('+')) {
      lastActiveStr = '${lastActiveStr}Z';
    }

    return ReferralInfo(
      referralId: json['referral_id'] as String,
      referralUsername: json['referral_username'] as String,
      referralDisplayName: json['referral_display_name'] as String?,
      isActive: json['is_active'] as bool,
      lastActiveAt: DateTime.parse(lastActiveStr),
      canBoost: json['can_boost'] as bool,
      activeBoostSessionId: json['active_boost_session_id'] as String?,
    );
  }
}


