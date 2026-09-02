class LeaderboardEntry {
  final String id;
  final String username;
  final String? displayName;
  final String country;
  final double balance;
  final int rank;

  LeaderboardEntry({
    required this.id,
    required this.username,
    this.displayName,
    required this.country,
    required this.balance,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      country: json['country'] as String? ?? 'US',
      balance: (json['balance'] as num).toDouble(),
      rank: json['rank'] as int? ?? 0,
    );
  }
}


