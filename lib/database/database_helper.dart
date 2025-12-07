/*
Database Helper for Expenses
Manages SQLite database operations for the expense tracking app

TO ACCESS/LOOKUP THE DATABASE
go to view -> tools windows -> app inspection -> database inspector (then it should pop up a window)

SQL Schema for Expenses:
Table: expenses
- id: INTEGER PRIMARY KEY AUTOINCREMENT
- amount: REAL NOT NULL (stores the expense amount as a decimal)
- category: TEXT NOT NULL (Food, Shopping, Gas, Bills, etc.)
- date: TEXT NOT NULL (format: YYYY-MM-DD)
- note: TEXT (optional notes about the expense)
- currency: TEXT NOT NULL DEFAULT 'USD' (supports future multi-currency (Hopefully))
- created_at: TEXT NOT NULL (timestamp when expense was created)
*/

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/expense.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    // Get the application documents directory
    final documentsDirectory = await getApplicationDocumentsDirectory();

    // Create a database subfolder in the documents directory
    final dbDirectory = Directory(join(documentsDirectory.path, 'database'));

    // Create the directory if it doesn't exist
    if (!await dbDirectory.exists()) {
      await dbDirectory.create(recursive: true);
    }

    // Full path to the database file
    final path = join(dbDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const realType = 'REAL NOT NULL';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT';

    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        amount $realType,
        category $textType,
        date $textType,
        note $textTypeNullable,
        currency $textType DEFAULT 'USD',
        created_at $textType
      )
    ''');
  }

  // Insert a new expense
  Future<int> createExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  // Get a single expense by ID
  Future<Expense?> getExpense(int id) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Expense.fromMap(maps.first);
    }
    return null;
  }

  // Get all expenses (ordered by date, most recent first)
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    // TODO: Add filtering by date range (e.g., current month only)
    final result = await db.query(
      'expenses',
      orderBy: 'date DESC, created_at DESC',
    );

    return result.map((map) => Expense.fromMap(map)).toList();
  }

  // Get expenses for a specific month
  Future<List<Expense>> getExpensesByMonth(int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String().substring(0, 10);
    final endDate = DateTime(year, month + 1, 0).toIso8601String().substring(0, 10);

    final result = await db.query(
      'expenses',
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date DESC',
    );

    return result.map((map) => Expense.fromMap(map)).toList();
  }

  // Get expenses by category
  Future<List<Expense>> getExpensesByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'expenses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'date DESC',
    );

    return result.map((map) => Expense.fromMap(map)).toList();
  }

  // Update an expense
  Future<int> updateExpense(Expense expense) async {
    final db = await database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // Delete an expense
  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get total spending for all expenses
  Future<double> getTotalSpending() async {
    final db = await database;
    // TODO: Add filtering by date range (e.g., current month only)
    final result = await db.rawQuery('SELECT SUM(amount) as total FROM expenses');
    return result.first['total'] as double? ?? 0.0;
  }

  // Get total spending by category
  Future<Map<String, double>> getSpendingByCategory() async {
    final db = await database;
    // TODO: Add filtering by date range (e.g., current month only)
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM expenses GROUP BY category',
    );

    final Map<String, double> categoryTotals = {};
    for (var row in result) {
      categoryTotals[row['category'] as String] = row['total'] as double;
    }
    return categoryTotals;
  }

  // Close the database
  Future close() async {
    final db = await database;
    db.close();
  }
}

