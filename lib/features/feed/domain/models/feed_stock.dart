class FeedStock {
  final String id;
  final String feedType;
  final double currentStockKg;
  final double averagePricePerKg;
  final DateTime lastRestockDate;
  final DateTime createdAt;
  final bool synced;

  FeedStock({
    required this.id,
    required this.feedType,
    required this.currentStockKg,
    required this.averagePricePerKg,
    required this.lastRestockDate,
    required this.createdAt,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'feedType': feedType,
      'currentStockKg': currentStockKg,
      'averagePricePerKg': averagePricePerKg,
      'lastRestockDate': lastRestockDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'synced': synced ? 1 : 0,
    };
  }

  factory FeedStock.fromMap(Map<String, dynamic> map) {
    return FeedStock(
      id: map['id'] as String,
      feedType: map['feedType'] as String,
      currentStockKg: (map['currentStockKg'] as num?)?.toDouble() ?? 0.0,
      averagePricePerKg: (map['averagePricePerKg'] as num?)?.toDouble() ?? 0.0,
      lastRestockDate: DateTime.parse(map['lastRestockDate'] as String),
      createdAt: map['createdAt'] != null 
          ? DateTime.parse(map['createdAt'] as String) 
          : DateTime.parse(map['lastRestockDate'] as String),
      synced: (map['synced'] as int? ?? 0) == 1,
    );
  }

  FeedStock copyWith({
    String? id,
    String? feedType,
    double? currentStockKg,
    double? averagePricePerKg,
    DateTime? lastRestockDate,
    DateTime? createdAt,
    bool? synced,
  }) {
    return FeedStock(
      id: id ?? this.id,
      feedType: feedType ?? this.feedType,
      currentStockKg: currentStockKg ?? this.currentStockKg,
      averagePricePerKg: averagePricePerKg ?? this.averagePricePerKg,
      lastRestockDate: lastRestockDate ?? this.lastRestockDate,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
    );
  }
}
