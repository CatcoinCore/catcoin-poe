class UserBadge {
  final String id;
  final String badgeType;
  final String? description;
  final DateTime awardedAt;
  final int? periodYear;
  final int? periodMonth;
  final int? podiumRank;
  final String? awardScope;
  final String? regionCode;
  final String? gameType;

  UserBadge({
    required this.id,
    required this.badgeType,
    this.description,
    required this.awardedAt,
    this.periodYear,
    this.periodMonth,
    this.podiumRank,
    this.awardScope,
    this.regionCode,
    this.gameType,
  });

  factory UserBadge.fromJson(Map<String, dynamic> json) {
    int? asInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    final rawId = json['id'];
    if (rawId == null) {
      throw FormatException('UserBadge JSON missing id');
    }

    return UserBadge(
      id: rawId.toString(),
      badgeType: json['badge_type'] as String,
      description: json['description'] as String?,
      awardedAt: DateTime.parse(json['awarded_at'] as String),
      periodYear: asInt(json['period_year']),
      periodMonth: asInt(json['period_month']),
      podiumRank: asInt(json['podium_rank']),
      awardScope: json['award_scope'] as String?,
      regionCode: json['region_code'] as String?,
      gameType: json['game_type'] as String?,
    );
  }
}


