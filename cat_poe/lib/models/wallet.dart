class Wallet {
  final String id;
  final String userId;
  final String catcoinAddress;
  final bool isPrimary;
  final String source;

  final double? balance;
  final int? daysMaintained;

  Wallet({
    required this.id,
    required this.userId,
    required this.catcoinAddress,
    required this.isPrimary,
    required this.source,
    this.balance,
    this.daysMaintained,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      catcoinAddress: json['catcoin_address'] as String,
      isPrimary: json['is_primary'] as bool,
      source: json['source'] as String? ?? 'MANUAL',
    );
  }

  Wallet copyWith({
    String? id,
    String? userId,
    String? catcoinAddress,
    bool? isPrimary,
    String? source,
    double? balance,
    int? daysMaintained,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      catcoinAddress: catcoinAddress ?? this.catcoinAddress,
      isPrimary: isPrimary ?? this.isPrimary,
      source: source ?? this.source,
      balance: balance ?? this.balance,
      daysMaintained: daysMaintained ?? this.daysMaintained,
    );
  }
}


