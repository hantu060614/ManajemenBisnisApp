class HealthLog {
  final String id;
  final String batchId;
  final String batchName;
  final DateTime date;
  final String type; // 'Vaksin', 'Obat', 'Penyakit', 'Kematian'
  final int amount; // For deaths or general dosage
  final String notes;
  final bool synced;

  HealthLog({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.date,
    required this.type,
    required this.amount,
    required this.notes,
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
      'notes': notes,
      'synced': synced ? 1 : 0,
    };
  }

  factory HealthLog.fromMap(Map<String, dynamic> map) {
    return HealthLog(
      id: map['id'] as String,
      batchId: map['batchId'] as String,
      batchName: map['batchName'] as String? ?? 'Unit Ternak',
      date: DateTime.parse(map['date'] as String),
      type: map['type'] as String? ?? 'Obat',
      amount: map['amount'] as int? ?? 0,
      notes: map['notes'] as String? ?? '',
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
