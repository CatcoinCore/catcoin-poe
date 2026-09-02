class ReferralBonusListItem {
  final String referralId;
  final String refereeUserId;
  final String refereeName;
  final DateTime refereeJoinedAt;
  final DateTime referredAt;
  final int bonusAmountCatoshi;
  final String bonusStatus;
  final int conditionsMetCount;

  ReferralBonusListItem({
    required this.referralId,
    required this.refereeUserId,
    required this.refereeName,
    required this.refereeJoinedAt,
    required this.referredAt,
    required this.bonusAmountCatoshi,
    required this.bonusStatus,
    required this.conditionsMetCount,
  });

  factory ReferralBonusListItem.fromJson(Map<String, dynamic> json) {
    return ReferralBonusListItem(
      referralId: json['referral_id'] as String,
      refereeUserId: json['referee_user_id'] as String,
      refereeName: json['referee_name'] as String,
      refereeJoinedAt: DateTime.parse(json['referee_joined_at'] as String),
      referredAt: DateTime.parse(json['referred_at'] as String),
      bonusAmountCatoshi: (json['bonus_amount_catoshi'] as num).toInt(),
      bonusStatus: json['bonus_status'] as String,
      conditionsMetCount: (json['conditions_met_count'] as num).toInt(),
    );
  }
}

class ReferralBonusConditionBlock {
  final int current;
  final int required;
  final bool met;

  ReferralBonusConditionBlock({
    required this.current,
    required this.required,
    required this.met,
  });

  factory ReferralBonusConditionBlock.fromJson(Map<String, dynamic> json) {
    return ReferralBonusConditionBlock(
      current: (json['current'] as num).toInt(),
      required: (json['required'] as num).toInt(),
      met: json['met'] as bool,
    );
  }
}

class ReferralBonusMiningCondition {
  final int currentCatoshi;
  final int requiredCatoshi;
  final bool met;

  ReferralBonusMiningCondition({
    required this.currentCatoshi,
    required this.requiredCatoshi,
    required this.met,
  });

  factory ReferralBonusMiningCondition.fromJson(Map<String, dynamic> json) {
    return ReferralBonusMiningCondition(
      currentCatoshi: (json['current_catoshi'] as num).toInt(),
      requiredCatoshi: (json['required_catoshi'] as num).toInt(),
      met: json['met'] as bool,
    );
  }
}

class ReferralBonusGameCondition {
  final int currentCatoshi;
  final int requiredCatoshi;
  final bool met;

  ReferralBonusGameCondition({
    required this.currentCatoshi,
    required this.requiredCatoshi,
    required this.met,
  });

  factory ReferralBonusGameCondition.fromJson(Map<String, dynamic> json) {
    return ReferralBonusGameCondition(
      currentCatoshi: (json['current_catoshi'] as num).toInt(),
      requiredCatoshi: (json['required_catoshi'] as num).toInt(),
      met: json['met'] as bool,
    );
  }
}

class ReferralBonusDetail {
  final String referralId;
  final String referrerUserId;
  final String refereeUserId;
  final String refereeName;
  final DateTime refereeJoinedAt;
  final DateTime referredAt;
  final int bonusAmountCatoshi;
  final String bonusStatus;
  final DateTime? bonusAwardedAt;
  final int conditionsMetCount;
  final ReferralBonusConditionBlock minedDays;
  final ReferralBonusMiningCondition miningReward;
  final ReferralBonusGameCondition gameReward;

  ReferralBonusDetail({
    required this.referralId,
    required this.referrerUserId,
    required this.refereeUserId,
    required this.refereeName,
    required this.refereeJoinedAt,
    required this.referredAt,
    required this.bonusAmountCatoshi,
    required this.bonusStatus,
    required this.bonusAwardedAt,
    required this.conditionsMetCount,
    required this.minedDays,
    required this.miningReward,
    required this.gameReward,
  });

  factory ReferralBonusDetail.fromJson(Map<String, dynamic> json) {
    final cond = json['conditions'] as Map<String, dynamic>;
    return ReferralBonusDetail(
      referralId: json['referral_id'] as String,
      referrerUserId: json['referrer_user_id'] as String,
      refereeUserId: json['referee_user_id'] as String,
      refereeName: json['referee_name'] as String,
      refereeJoinedAt: DateTime.parse(json['referee_joined_at'] as String),
      referredAt: DateTime.parse(json['referred_at'] as String),
      bonusAmountCatoshi: (json['bonus_amount_catoshi'] as num).toInt(),
      bonusStatus: json['bonus_status'] as String,
      bonusAwardedAt: json['bonus_awarded_at'] != null
          ? DateTime.parse(json['bonus_awarded_at'] as String)
          : null,
      conditionsMetCount: (json['conditions_met_count'] as num).toInt(),
      minedDays: ReferralBonusConditionBlock.fromJson(
          cond['mined_days'] as Map<String, dynamic>),
      miningReward: ReferralBonusMiningCondition.fromJson(
          cond['mining_reward'] as Map<String, dynamic>),
      gameReward: ReferralBonusGameCondition.fromJson(
          cond['game_reward'] as Map<String, dynamic>),
    );
  }
}
