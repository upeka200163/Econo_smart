import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:econosmart/expense_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'smart_money_manager.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL,
        time TEXT NOT NULL,
        isIncome INTEGER NOT NULL,
        accountType TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        month TEXT NOT NULL,
        year INTEGER NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
          'ALTER TABLE transactions ADD COLUMN title TEXT NOT NULL DEFAULT ""');
    }
  }

  // CRUD Operations for Transactions
  Future<int> insertTransaction(ExpenseModel transaction) async {
    Database db = await database;
    return await db.insert('transactions', transaction.toMap(includeId: false));
  }

  Future<List<ExpenseModel>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? accountType,
    bool? isIncome,
  }) async {
    Database db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause += 'date BETWEEN ? AND ?';
      whereArgs.add(startDate.toIso8601String().split('T')[0]);
      whereArgs.add(endDate.toIso8601String().split('T')[0]);
    }

    if (category != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'category = ?';
      whereArgs.add(category);
    }

    if (accountType != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'accountType = ?';
      whereArgs.add(accountType);
    }

    if (isIncome != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'isIncome = ?';
      whereArgs.add(isIncome ? 1 : 0);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'createdAt DESC',
    );

    return List.generate(maps.length, (i) => ExpenseModel.fromMap(maps[i]));
  }

  Future<int> updateTransaction(ExpenseModel transaction) async {
    Database db = await database;
    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [int.parse(transaction.id)],
    );
  }

  Future<int> deleteTransaction(int id) async {
    Database db = await database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Budget Operations
  Future<int> insertBudget(
      String category, double amount, DateTime month) async {
    Database db = await database;
    return await db.insert('budgets', {
      'category': category,
      'amount': amount,
      'month': '${month.year}-${month.month.toString().padLeft(2, '0')}',
      'year': month.year,
    });
  }

  Future<double?> getBudget(String category, DateTime month) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'budgets',
      where: 'category = ? AND month = ?',
      whereArgs: [
        category,
        '${month.year}-${month.month.toString().padLeft(2, '0')}'
      ],
    );

    if (maps.isNotEmpty) {
      return (maps.first['amount'] as num?)?.toDouble();
    }
    return null;
  }

  Future<int> updateBudget(
      String category, double amount, DateTime month) async {
    Database db = await database;
    return await db.update(
      'budgets',
      {'amount': amount},
      where: 'category = ? AND month = ?',
      whereArgs: [
        category,
        '${month.year}-${month.month.toString().padLeft(2, '0')}'
      ],
    );
  }

  // Summary Calculations
  Future<Map<String, double>> getMonthlySummary(DateTime month) async {
    Database db = await database;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as totalIncome,
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as totalExpenses,
        SUM(amount * CASE WHEN isIncome = 1 THEN 1 ELSE -1 END) as balance
      FROM transactions
      WHERE date BETWEEN ? AND ?
    ''', [
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0]
    ]);

    final result = maps.first;
    return {
      'totalIncome': (result['totalIncome'] as num? ?? 0.0).toDouble(),
      'totalExpenses': (result['totalExpenses'] as num? ?? 0.0).toDouble(),
      'balance': (result['balance'] as num? ?? 0.0).toDouble(),
    };
  }

  Future<Map<String, double>> getOverallSummary() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT
        SUM(CASE WHEN isIncome = 1 THEN amount ELSE 0 END) as totalIncome,
        SUM(CASE WHEN isIncome = 0 THEN amount ELSE 0 END) as totalExpenses,
        SUM(amount * CASE WHEN isIncome = 1 THEN 1 ELSE -1 END) as balance
      FROM transactions
    ''');
    final result = maps.first;
    return {
      'totalIncome': (result['totalIncome'] as num? ?? 0.0).toDouble(),
      'totalExpenses': (result['totalExpenses'] as num? ?? 0.0).toDouble(),
      'balance': (result['balance'] as num? ?? 0.0).toDouble(),
    };
  }

  Future<Map<String, double>> getCategorySummary(DateTime month) async {
    Database db = await database;
    final startDate = DateTime(month.year, month.month, 1);
    final endDate = DateTime(month.year, month.month + 1, 0);

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT category, SUM(amount) as total
      FROM transactions
      WHERE date BETWEEN ? AND ? AND isIncome = 0
      GROUP BY category
    ''', [
      startDate.toIso8601String().split('T')[0],
      endDate.toIso8601String().split('T')[0]
    ]);

    return {
      for (var map in maps)
        map['category'] as String: (map['total'] as num? ?? 0.0).toDouble()
    };
  }
}
