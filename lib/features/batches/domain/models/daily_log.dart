class DailyLog {
  final String id;
  final String batchId;
  final DateTime logDate;
  final double feedAmount;
  final int mortalityCount;
  final double estimatedWeight;
  final bool synced;

  DailyLog({
    required this.id,
    required this.batchId,
    required this.logDate,
    required this.feedAmount,
    required this.mortalityCount,
    required this.estimatedWeight,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'logDate': logDate.toIso8601String(),
      'feedAmount': feedAmount,
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
      feedAmount: map['feedAmount'] as double,
      mortalityCount: map['mortalityCount'] as int,
      estimatedWeight: map['estimatedWeight'] as double,
      synced: (map['synced'] as int) == 1,
    );
  }
}
