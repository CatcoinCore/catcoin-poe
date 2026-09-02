class MiningSession {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  MiningSession({
    required this.id,
    required this.userId,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory MiningSession.fromJson(Map<String, dynamic> json) {
    // Backend sends naive UTC datetimes without 'Z' suffix
    // We need to parse them as UTC explicitly
    String startTimeStr = json['start_time'] as String;
    String endTimeStr = json['end_time'] as String;

    // If no timezone marker, treat as UTC
    if (!startTimeStr.endsWith('Z') && !startTimeStr.contains('+')) {
      startTimeStr = '${startTimeStr}Z';
    }
    if (!endTimeStr.endsWith('Z') && !endTimeStr.contains('+')) {
      endTimeStr = '${endTimeStr}Z';
    }

    return MiningSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      startTime: DateTime.parse(startTimeStr),
      endTime: DateTime.parse(endTimeStr),
      status: json['status'] as String,
    );
  }
}


