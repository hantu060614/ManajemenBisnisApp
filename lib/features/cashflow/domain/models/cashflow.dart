class Cashflow {
  final String id;
  final String type; // 'income' or 'expense'
  final double amount;
  final String category;
  final String? description;
  final DateTime date;
  final bool synced;

  Cashflow({
    required this.id,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.date,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory Cashflow.fromMap(Map<String, dynamic> map) {
    return Cashflow(
      id: map['id'] as String,
      type: map['type'] as String,
      amount: map['amount'] as double,
      category: map['category'] as String,
      description: map['description'] as String?,
      date: DateTime.parse(map['date'] as String),
      synced: (map['synced'] as int) == 1,
    );
  }
}
