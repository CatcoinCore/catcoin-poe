import 'time_boost_slot.dart';

class ActiveSession {
  final String id;
  final String sessionType;
  final String? miningFor;
  final double yieldPercentage;
  final DateTime startTime;
  final DateTime endTime;
  final double totalEarned;
  final int rewardY;
  final int rewardT;
  final double referralBoostPercentage; // New field
  final List<TimeBoostSlot>? timeBoostSlots;

  ActiveSession({
    required this.id,
    required this.sessionType,
    this.miningFor,
    required this.yieldPercentage,
    required this.startTime,
    required this.endTime,
    required this.totalEarned,
    required this.rewardY,
    required this.rewardT,
    this.referralBoostPercentage = 0.0, // Added to constructor with default
    this.timeBoostSlots,
  });

  factory ActiveSession.fromJson(Map<String, dynamic> json) {
    // Safely parse datetime strings with null checks
    String startTimeStr = (json['start_time'] as String?) ??
        DateTime.now().toUtc().toIso8601String();
    String endTimeStr = (json['end_time'] as String?) ??
        DateTime.now().toUtc().toIso8601String();

    if (!startTimeStr.endsWith('Z') && !startTimeStr.contains('+')) {
      startTimeStr = '${startTimeStr}Z';
    }
    if (!endTimeStr.endsWith('Z') && !endTimeStr.contains('+')) {
      endTimeStr = '${endTimeStr}Z';
    }

    final rawSlots = json['time_boost_slots'] as List<dynamic>?;
    List<TimeBoostSlot>? slots;
    if (rawSlots != null && rawSlots.isNotEmpty) {
      slots = rawSlots
          .map((e) => TimeBoostSlot.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return ActiveSession(
      id: json['id'] as String,
      sessionType: json['session_type'] as String,
      miningFor: json['mining_for'] as String?,
      yieldPercentage: (json['yield_percentage'] as num?)?.toDouble() ?? 0.0,
      referralBoostPercentage: // Added parsing for new field
          (json['referral_boost_percentage'] as num?)?.toDouble() ?? 0.0,
      startTime: DateTime.parse(startTimeStr),
      endTime: DateTime.parse(endTimeStr),
      totalEarned: (json['total_earned'] as num?)?.toDouble() ?? 0.0,
      rewardY: json['reward_y'] as int? ?? 0,
      rewardT: json['reward_t'] as int? ?? 1,
      timeBoostSlots: slots,
    );
  }
}


