class Batch {
  final String id;
  final String name;
  final String animalCategory;
  final String animalType;
  final int initialCount;
  final int currentCount;
  final DateTime startDate;
  final bool isActive;
  final bool synced;

  Batch({
    required this.id,
    required this.name,
    required this.animalCategory,
    required this.animalType,
    required this.initialCount,
    required this.currentCount,
    required this.startDate,
    required this.isActive,
    this.synced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'animalCategory': animalCategory,
      'animalType': animalType,
      'initialCount': initialCount,
      'currentCount': currentCount,
      'startDate': startDate.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'synced': synced ? 1 : 0,
    };
  }

  factory Batch.fromMap(Map<String, dynamic> map) {
    return Batch(
      id: map['id'] as String,
      name: map['name'] as String,
      animalCategory: map['animalCategory'] as String? ?? 'Lainnya',
      animalType: map['animalType'] as String,
      initialCount: map['initialCount'] as int,
      currentCount: map['currentCount'] as int,
      startDate: DateTime.parse(map['startDate'] as String),
      isActive: (map['isActive'] as int) == 1,
      synced: (map['synced'] as int) == 1,
    );
  }
}
