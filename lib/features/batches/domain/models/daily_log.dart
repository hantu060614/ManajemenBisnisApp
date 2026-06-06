class DailyLog {
  final String id;
  final String batchId;
  final DateTime logDate;
  final double feedAmount;
  final String feedUnit; // Tambahan properti satuan pakan
  final int mortalityCount;
  final double estimatedWeight;
  final bool synced;

  DailyLog({
    required this.id,
    required this.batchId,
    required this.logDate,
    required this.feedAmount,
    required this.feedUnit,
    required this.mortalityCount,
    required this.estimatedWeight,
    this.synced = false,
  });

  // Mengonversi jumlah pakan secara otomatis ke Kilogram
  double get feedAmountInKg {
    switch (feedUnit.toLowerCase()) {
      case 'g':
        return feedAmount / 1000.0;
      case 'ons':
        return feedAmount / 10.0;
      case 'kg':
      default:
        return feedAmount;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'logDate': logDate.toIso8601String(),
      'feedAmount': feedAmount,
      'feedUnit': feedUnit,
      'mortalityCount': mortalityCount,
      'estimatedWeight': estimatedWeight,
      'synced': synced ? 1 : 0,
    };
  }

  factory DailyLog.fromMap(Map<String, dynamic> map) {
    return DailyLog(
      id: map['id'] as String,
      batchId: map['batchId'] as String,
      logDate: DateTime.parse(map['logDate'] as String),
      feedAmount: (map['feedAmount'] as num).toDouble(),
      feedUnit: map['feedUnit'] as String? ?? 'kg', // Nilai default kg demi kompatibilitas data lama
      mortalityCount: map['mortalityCount'] as int,
      estimatedWeight: (map['estimatedWeight'] as num).toDouble(),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
