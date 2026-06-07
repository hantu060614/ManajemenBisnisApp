class FeedLog {
  final String id;
  final String batchId;
  final String batchName;
  final DateTime date;
  final String feedType;
  final double amountKg;
  final double amountOns;
  final double amountGram;
  final double pricePerKg;
  final String? notes;
  final String feedingTime; // 'Pagi', 'Siang', 'Sore'
  final int mortalityCount; // Opsional/tambahan
  final double estimatedWeight; // Opsional/tambahan
  final bool synced;

  FeedLog({
    required this.id,
    required this.batchId,
    required this.batchName,
    required this.date,
    required this.feedType,
    required this.amountKg,
    required this.amountOns,
    required this.amountGram,
    required this.pricePerKg,
    this.notes,
    required this.feedingTime,
    this.mortalityCount = 0,
    this.estimatedWeight = 0.0,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batchId': batchId,
      'batchName': batchName,
      'date': date.toIso8601String(),
      'feedType': feedType,
      'amountKg': amountKg,
      'amountOns': amountOns,
      'amountGram': amountGram,
      'pricePerKg': pricePerKg,
      'notes': notes,
      'feedingTime': feedingTime,
      'mortalityCount': mortalityCount,
      'estimatedWeight': estimatedWeight,
      'synced': synced ? 1 : 0,
    };
  }

  factory FeedLog.fromMap(Map<String, dynamic> map) {
    double kg = (map['amountKg'] as num?)?.toDouble() ?? 0.0;
    double ons = (map['amountOns'] as num?)?.toDouble() ?? 0.0;
    double gram = (map['amountGram'] as num?)?.toDouble() ?? 0.0;

    // Backward compatibility conversion: if gram is 0 but kg/ons are not, calculate it.
    if (gram == 0.0) {
      if (kg > 0) {
        gram = kg * 1000;
        ons = kg * 10;
      } else if (ons > 0) {
        gram = ons * 100;
        kg = ons / 10;
      }
    }

    return FeedLog(
      id: map['id'] as String,
      batchId: map['batchId'] as String,
      batchName: map['batchName'] as String? ?? 'Kolam',
      date: DateTime.parse(map['date'] as String),
      feedType: map['feedType'] as String? ?? '',
      amountKg: kg,
      amountOns: ons,
      amountGram: gram,
      pricePerKg: (map['pricePerKg'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      feedingTime: map['feedingTime'] as String? ?? 'Pagi',
      mortalityCount: (map['mortalityCount'] as num?)?.toInt() ?? 0,
      estimatedWeight: (map['estimatedWeight'] as num?)?.toDouble() ?? 0.0,
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }
}
