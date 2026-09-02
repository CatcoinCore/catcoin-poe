import 'active_session.dart';
import 'referral_info.dart';

class EarningsBreakdown {
  final double miningBase;
  final double miningReferralBoost;
  final double socialFacebook;
  final double socialX;
  final double missionCompletion;
  final double referralSignupBonus;
  final double airdrop;

  EarningsBreakdown({
    this.miningBase = 0.0,
    this.miningReferralBoost = 0.0,
    this.socialFacebook = 0.0,
    this.socialX = 0.0,
    this.missionCompletion = 0.0,
    this.referralSignupBonus = 0.0,
    this.airdrop = 0.0,
  });

  factory EarningsBreakdown.fromJson(Map<String, dynamic> json) {
    return EarningsBreakdown(
      miningBase: (json['MINING_BASE'] as num?)?.toDouble() ?? 0.0,
      miningReferralBoost:
          (json['MINING_REFERRAL_BOOST'] as num?)?.toDouble() ?? 0.0,
      socialFacebook: (json['SOCIAL_FACEBOOK'] as num?)?.toDouble() ?? 0.0,
      socialX: (json['SOCIAL_X'] as num?)?.toDouble() ?? 0.0,
      missionCompletion:
          (json['MISSION_COMPLETION'] as num?)?.toDouble() ?? 0.0,
      referralSignupBonus:
          (json['REFERRAL_SIGNUP_BONUS'] as num?)?.toDouble() ?? 0.0,
      airdrop: (json['AIRDROP'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class EnhancedStats {
  final double balance;
  final double yieldPercentage;
  final double referralBoostPercentage; // New field
  final List<ActiveSession> activeSessions;
  final EarningsBreakdown earningsBreakdown;
  final double totalVerifiedEarnings;
  final double totalUnverifiedEarnings;
  final List<ReferralInfo> availableReferrals;

  EnhancedStats({
    required this.balance,
    required this.yieldPercentage,
    this.referralBoostPercentage = 0.0,
    required this.activeSessions,
    required this.earningsBreakdown,
    required this.totalVerifiedEarnings,
    required this.totalUnverifiedEarnings,
    required this.availableReferrals,
  });

  factory EnhancedStats.fromJson(Map<String, dynamic> json) {
    var activeSessionsList = json['active_sessions'] as List? ?? [];
    var referralsList = json['available_referrals'] as List? ?? [];

    return EnhancedStats(
      balance: (json['balance'] as num).toDouble(),
      yieldPercentage: (json['yield_percentage'] as num).toDouble(),
      referralBoostPercentage:
          (json['referral_boost_percentage'] as num?)?.toDouble() ?? 0.0,
      activeSessions:
          activeSessionsList.map((s) => ActiveSession.fromJson(s)).toList(),
      earningsBreakdown: EarningsBreakdown.fromJson(json['earnings_breakdown']),
      totalVerifiedEarnings:
          (json['total_verified_earnings'] as num).toDouble(),
      totalUnverifiedEarnings:
          (json['total_unverified_earnings'] as num).toDouble(),
      availableReferrals:
          referralsList.map((r) => ReferralInfo.fromJson(r)).toList(),
    );
  }

  // Helper for backward compatibility
  ActiveSession? get primarySession =>
      activeSessions.isNotEmpty ? activeSessions.first : null;
}


