/*
Expense Model
Represents a single expense entry in the database
*/

class Expense {
  final int? id;
  final double amount;
  final String category;
  final String date; // String (YYYY-MM-DD)
  final String? note;
  final String currency; // Default: USD, scalable to other currencies
  final String createdAt;

  Expense({
    this.id,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.currency = 'USD',
    String? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String();

  // Convert Expense to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'date': date,
      'note': note,
      'currency': currency,
      'created_at': createdAt,
    };
  }

  // Create Expense from Map (database query result)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      category: map['category'] as String,
      date: map['date'] as String,
      note: map['note'] as String?,
      currency: map['currency'] as String? ?? 'USD',
      createdAt: map['created_at'] as String,
    );
  }

  // Create a copy of Expense with modified fields
  Expense copyWith({
    int? id,
    double? amount,
    String? category,
    String? date,
    String? note,
    String? currency,
    String? createdAt,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Expense{id: $id, amount: $amount, category: $category, date: $date, note: $note, currency: $currency, createdAt: $createdAt}';
  }
}

// Available expense categories
// Feel free to add more categories as needed/wanted
class ExpenseCategories {
  static const String food = 'Food';
  static const String shopping = 'Shopping';
  static const String gas = 'Gas';
  static const String bills = 'Bills';
  static const String entertainment = 'Entertainment';
  static const String healthcare = 'Healthcare';
  static const String transportation = 'Transportation';
  static const String other = 'Other';

  static const List<String> all = [
    food,
    shopping,
    gas,
    bills,
    entertainment,
    healthcare,
    transportation,
    other,
  ];
}

