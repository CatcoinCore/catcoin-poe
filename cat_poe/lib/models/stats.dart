import 'mining_session.dart';

class Stats {
  final double balance;
  final double hashrate;
  final MiningSession? activeSession;

  Stats({
    required this.balance,
    required this.hashrate,
    this.activeSession,
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      balance: (json['balance'] as num).toDouble(),
      hashrate: (json['hashrate'] as num).toDouble(),
      activeSession: json['active_session'] != null
          ? MiningSession.fromJson(json['active_session'])
          : null,
    );
  }
}


