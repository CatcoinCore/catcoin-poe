class Mission {
  final String id;
  final String code;
  final String title;
  final String? description;
  final String? link;
  final String? icon;
  final String type;
  final double rewardAmount;
  final bool isCompleted;
  final String? status;
  final bool isActive;

  final DateTime? createdAt;
  final DateTime? expiresAt;
  final String? prerequisiteId;

  Mission({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    this.link,
    this.icon,
    required this.type,
    required this.rewardAmount,
    this.isCompleted = false,
    this.status,
    this.isActive = true,
    this.createdAt,
    this.expiresAt,
    this.prerequisiteId,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      code: json['code'],
      title: json['title'] ?? '',
      description: json['description'],
      link: json['link'],
      icon: json['icon'],
      type: json['type'],
      rewardAmount: (json['reward_amount'] as num).toDouble(),
      isCompleted: json['is_completed'] ?? false,
      status: json['status'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      prerequisiteId: json['prerequisite_id'],
    );
  }
}


