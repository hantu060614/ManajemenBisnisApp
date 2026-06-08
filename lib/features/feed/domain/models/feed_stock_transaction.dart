class FeedStockTransaction {
  final String id;
  final String feedStockId;
  final String transactionType; // 'buy' or 'use'
  final double amountKg;
  final double pricePerKg;
  final double totalPrice;
  final DateTime date;
  final String referenceId; // Cashflow ID (buy) or FeedLog ID (use)
  final bool synced;

  FeedStockTransaction({
    required this.id,
    required this.feedStockId,
    required this.transactionType,
    required this.amountKg,
    required this.pricePerKg,
    required this.totalPrice,
    required this.date,
    required this.referenceId,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feedStockId': feedStockId,
      'transactionType': transactionType,
      'amountKg': amountKg,
      'pricePerKg': pricePerKg,
      'totalPrice': totalPrice,
      'date': date.toIso8601String(),
      'referenceId': referenceId,
      'synced': synced ? 1 : 0,
    };
  }

  factory FeedStockTransaction.fromMap(Map<String, dynamic> map) {
    return FeedStockTransaction(
      id: map['id'] as String,
      feedStockId: map['feedStockId'] as String,
      transactionType: map['transactionType'] as String,
      amountKg: (map['amountKg'] as num?)?.toDouble() ?? 0.0,
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.parse(map['date'] as String),
      referenceId: map['referenceId'] as String,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
