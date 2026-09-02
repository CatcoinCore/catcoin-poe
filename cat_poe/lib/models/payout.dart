class Payout {
  final String id;
  final String catcoinAddress;
  final double amountCat;
  final String status;
  final String? txid;
  final DateTime createdAt;
  final DateTime? sentAt;

  Payout({
    required this.id,
    required this.catcoinAddress,
    required this.amountCat,
    required this.status,
    this.txid,
    required this.createdAt,
    this.sentAt,
  });

  factory Payout.fromJson(Map<String, dynamic> json) {
    return Payout(
      id: json['id'],
      catcoinAddress: json['catcoin_address'],
      amountCat: (json['amount_cat'] as num).toDouble(),
      status: json['status'],
      txid: json['txid'],
      createdAt: DateTime.parse(json['created_at']),
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
    );
  }
}


