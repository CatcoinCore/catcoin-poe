class UserGameBoost {
  final String id;
  final String userId;
  final double percentage;
  final int durationMinutes;
  final bool isUsed;
  final String? sessionId;
  final DateTime earnedAt;

  UserGameBoost({
    required this.id,
    required this.userId,
    required this.percentage,
    required this.durationMinutes,
    required this.isUsed,
    this.sessionId,
    required this.earnedAt,
  });

  factory UserGameBoost.fromJson(Map<String, dynamic> json) {
    return UserGameBoost(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      percentage: (json['percentage'] as num).toDouble(),
      durationMinutes: json['duration_minutes'] as int,
      isUsed: json['is_used'] as bool? ?? false,
      sessionId: json['session_id'] as String?,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }
}
