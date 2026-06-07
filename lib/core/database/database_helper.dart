import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('farm_management.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';

    if (oldVersion < 2) {
      await db.execute("ALTER TABLE batches ADD COLUMN animalCategory TEXT DEFAULT 'Lainnya'");
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE feed_stock (
          id $idType,
          feedType $textType,
          currentStockKg $realType,
          averagePricePerKg $realType,
          lastRestockDate $textType,
          synced $boolType DEFAULT 0
        )
      ''');
      await db.execute('''
        CREATE TABLE feed_stock_transactions (
          id $idType,
          feedStockId $textType,
          transactionType $textType,
          amountKg $realType,
          pricePerKg $realType,
          totalPrice $realType,
          date $textType,
          referenceId $textType,
          synced $boolType DEFAULT 0
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const integerType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';
    const boolType = 'BOOLEAN NOT NULL';

    // Users Table
    await db.execute('''
      CREATE TABLE users (
        id $idType,
        name $textType,
        email $textType,
        photoUrl TEXT,
        createdAt $textType
      )
    ''');

    // Batches (Kolam/Kandang) Table
    await db.execute('''
      CREATE TABLE batches (
        id $idType,
        name $textType,
        animalCategory $textType,
        animalType $textType,
        initialCount $integerType,
        currentCount $integerType,
        startDate $textType,
        isActive $boolType,
        synced $boolType DEFAULT 0
      )
    ''');

    // Daily Logs (Pakan, Kematian, Berat)
    await db.execute('''
      CREATE TABLE daily_logs (
        id $idType,
        batchId $textType,
        logDate $textType,
        feedAmount $realType,
        mortalityCount $integerType,
        estimatedWeight $realType,
        synced $boolType DEFAULT 0,
        FOREIGN KEY (batchId) REFERENCES batches (id) ON DELETE CASCADE
      )
    ''');

    // Cashflow (Keuangan)
    await db.execute('''
      CREATE TABLE cashflow (
        id $idType,
        type $textType,
        amount $realType,
        category $textType,
        description TEXT,
        date $textType,
        synced $boolType DEFAULT 0
      )
    ''');

    // Feed Stock (Stok Pakan)
    await db.execute('''
      CREATE TABLE feed_stock (
        id $idType,
        feedType $textType,
        currentStockKg $realType,
        averagePricePerKg $realType,
        lastRestockDate $textType,
        synced $boolType DEFAULT 0
      )
    ''');

    // Feed Stock Transactions (Riwayat Stok)
    await db.execute('''
      CREATE TABLE feed_stock_transactions (
        id $idType,
        feedStockId $textType,
        transactionType $textType,
        amountKg $realType,
        pricePerKg $realType,
        totalPrice $realType,
        date $textType,
        referenceId $textType,
        synced $boolType DEFAULT 0
      )
    ''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
