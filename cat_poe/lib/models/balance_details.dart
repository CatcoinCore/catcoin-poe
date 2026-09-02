import 'wallet.dart';

class BalanceDetails {
  final Wallet? primaryWallet;
  final Map<String, double> earningsBreakdown;
  final Map<String, bool> withdrawalPermissions;
  final double totalBalance;
  final double gameWithdrawalThreshold;
  final bool globalWithdrawalEnabled;

  BalanceDetails({
    this.primaryWallet,
    required this.earningsBreakdown,
    required this.withdrawalPermissions,
    required this.totalBalance,
    this.gameWithdrawalThreshold = 100000000.0,
    this.globalWithdrawalEnabled = true,
  });

  factory BalanceDetails.fromJson(Map<String, dynamic> json) {
    return BalanceDetails(
      primaryWallet: json['primary_wallet'] != null 
          ? Wallet.fromJson(json['primary_wallet']) 
          : null,
      earningsBreakdown: Map<String, double>.from(
          json['earnings_breakdown'].map((k, v) => MapEntry(k, (v as num).toDouble()))),
      withdrawalPermissions: Map<String, bool>.from(json['withdrawal_permissions']),
      totalBalance: (json['total_balance'] as num).toDouble(),
      gameWithdrawalThreshold: (json['game_withdrawal_threshold'] as num?)?.toDouble() ?? 100000000.0,
      globalWithdrawalEnabled: json['global_withdrawal_enabled'] ?? true,
    );
  }
}

class EarningsLedgerEntry {
  final String id;
  final double amount;
  final String rewardType;
  final String? description;
  final DateTime createdAt;
  final bool isVerified;

  EarningsLedgerEntry({
    required this.id,
    required this.amount,
    required this.rewardType,
    this.description,
    required this.createdAt,
    required this.isVerified,
  });

  factory EarningsLedgerEntry.fromJson(Map<String, dynamic> json) {
    return EarningsLedgerEntry(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      rewardType: json['reward_type'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
      isVerified: json['is_verified'] ?? false,
    );
  }
}

