class TimeBoostSlot {
  final int hours;
  final DateTime? cooldownUntil;
  final bool active;

  TimeBoostSlot({
    required this.hours,
    this.cooldownUntil,
    this.active = true,
  });

  factory TimeBoostSlot.fromJson(Map<String, dynamic> json) {
    DateTime? cd;
    final raw = json['cooldown_until'] as String?;
    if (raw != null) {
      var s = raw;
      if (!s.endsWith('Z') && !s.contains('+')) {
        s = '${s}Z';
      }
      cd = DateTime.parse(s).toUtc();
    }
    return TimeBoostSlot(
      hours: (json['hours'] as num).toInt(),
      cooldownUntil: cd,
      active: json['active'] as bool? ?? true,
    );
  }
}
