class ProductionLog {
  final String id;
  final String batchId;
  final String batchName;
  final DateTime date;
  final String type; // 'Telur', 'Susu', 'Bobot Sampling'
  final double amount;
  final String unit; // 'Butir', 'Liter', 'Gram/Ekor'
  final String? notes;
  final bool synced;

  ProductionLog({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.date,
    required this.type,
    required this.amount,
    required this.unit,
    this.notes,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'batchName': batchName,
      'date': date.toIso8601String(),
      'type': type,
      'amount': amount,
      'unit': unit,
      'notes': notes,
      'synced': synced ? 1 : 0,
    };
  }

  factory ProductionLog.fromMap(Map<String, dynamic> map) {
    return ProductionLog(
      id: map['id'] as String,
      batchId: map['batchId'] as String,
      batchName: map['batchName'] as String? ?? 'Unit Ternak',
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String? ?? 'Bobot Sampling',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? 'Gram/Ekor',
      notes: map['notes'] as String?,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
