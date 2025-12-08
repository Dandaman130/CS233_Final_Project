/*
Incomes Model
Represents a single expense entry in the database
*/

class Incomes {
  final int? id;
  final double amount;
  final String category;
  final String date; // String (YYYY-MM-DD)
  final String? note;
  final String currency; // Default: USD, scalable to other currencies
  final String createdAt;

  Incomes({
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
  factory Incomes.fromMap(Map<String, dynamic> map) {
    return Incomes(
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
  Incomes copyWith({
    int? id,
    double? amount,
    String? category,
    String? date,
    String? note,
    String? currency,
    String? createdAt,
  }) {
    return Incomes(
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
    return 'Income{id: $id, amount: $amount, category: $category, date: $date, note: $note, currency: $currency, createdAt: $createdAt}';
  }
}

// Available expense categories
// Feel free to add more categories as needed/wanted
class IncomeCategories {
  static const String salary = 'Salary';
  static const String selfEmployment = 'Self Employment';
  static const String bonus = 'Bonus';
  static const String capitalGain = 'Capital Gain';
  static const String other = 'Other';

  static const List<String> all = [
    salary,
    selfEmployment,
    bonus,
    capitalGain,
    other,
  ];
}

