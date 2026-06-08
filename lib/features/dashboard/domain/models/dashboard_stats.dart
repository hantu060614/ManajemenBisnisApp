class DashboardStats {
  final double totalIncome;
  final double totalExpense;
  final double cashflowBalance;
  final double incomeToday;
  final double expenseToday;
  final double incomeThisMonth;
  final double expenseThisMonth;
  final double feedOutToday;
  final int totalAnimals;
  final int activeBatches;
  final DateTime lastUpdatedDate;
  final bool isMigrated;

  DashboardStats({
    required this.totalIncome,
    required this.totalExpense,
    required this.cashflowBalance,
    required this.incomeToday,
    required this.expenseToday,
    required this.incomeThisMonth,
    required this.expenseThisMonth,
    required this.feedOutToday,
    required this.totalAnimals,
    required this.activeBatches,
    required this.lastUpdatedDate,
    required this.isMigrated,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalIncome: 0,
      totalExpense: 0,
      cashflowBalance: 0,
      incomeToday: 0,
      expenseToday: 0,
      incomeThisMonth: 0,
      expenseThisMonth: 0,
      feedOutToday: 0,
      totalAnimals: 0,
      activeBatches: 0,
      lastUpdatedDate: DateTime.now(),
      isMigrated: false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'cashflowBalance': cashflowBalance,
      'incomeToday': incomeToday,
      'expenseToday': expenseToday,
      'incomeThisMonth': incomeThisMonth,
      'expenseThisMonth': expenseThisMonth,
      'feedOutToday': feedOutToday,
      'totalAnimals': totalAnimals,
      'activeBatches': activeBatches,
      'lastUpdatedDate': lastUpdatedDate.toIso8601String(),
      'isMigrated': isMigrated ? 1 : 0,
    };
  }

  factory DashboardStats.fromMap(Map<String, dynamic> map) {
    return DashboardStats(
      totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (map['totalExpense'] as num?)?.toDouble() ?? 0.0,
      cashflowBalance: (map['cashflowBalance'] as num?)?.toDouble() ?? 0.0,
      incomeToday: (map['incomeToday'] as num?)?.toDouble() ?? 0.0,
      expenseToday: (map['expenseToday'] as num?)?.toDouble() ?? 0.0,
      incomeThisMonth: (map['incomeThisMonth'] as num?)?.toDouble() ?? 0.0,
      expenseThisMonth: (map['expenseThisMonth'] as num?)?.toDouble() ?? 0.0,
      feedOutToday: (map['feedOutToday'] as num?)?.toDouble() ?? 0.0,
      totalAnimals: map['totalAnimals'] as int? ?? 0,
      activeBatches: map['activeBatches'] as int? ?? 0,
      lastUpdatedDate: map['lastUpdatedDate'] != null 
          ? DateTime.parse(map['lastUpdatedDate'] as String) 
          : DateTime.now(),
      isMigrated: (map['isMigrated'] as int? ?? 0) == 1,
    );
  }

  DashboardStats copyWith({
    double? totalIncome,
    double? totalExpense,
    double? cashflowBalance,
    double? incomeToday,
    double? expenseToday,
    double? incomeThisMonth,
    double? expenseThisMonth,
    double? feedOutToday,
    int? totalAnimals,
    int? activeBatches,
    DateTime? lastUpdatedDate,
    bool? isMigrated,
  }) {
    return DashboardStats(
      totalIncome: totalIncome ?? this.totalIncome,
      totalExpense: totalExpense ?? this.totalExpense,
      cashflowBalance: cashflowBalance ?? this.cashflowBalance,
      incomeToday: incomeToday ?? this.incomeToday,
      expenseToday: expenseToday ?? this.expenseToday,
      incomeThisMonth: incomeThisMonth ?? this.incomeThisMonth,
      expenseThisMonth: expenseThisMonth ?? this.expenseThisMonth,
      feedOutToday: feedOutToday ?? this.feedOutToday,
      totalAnimals: totalAnimals ?? this.totalAnimals,
      activeBatches: activeBatches ?? this.activeBatches,
      lastUpdatedDate: lastUpdatedDate ?? this.lastUpdatedDate,
      isMigrated: isMigrated ?? this.isMigrated,
    );
  }
}
