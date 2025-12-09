/*
This page will allow for users to enter their expenses. With each entry,
the app will keep track of the total amount of expenses that the user has
spent within the month, along with a breakdown of spending habits per category.

Features Implemented:
- Add expenses (via FAB button)
- Delete entries (long-press on expense card)
- Categorical summary with pie chart
- Total spending calculation
- Chronological expense list with icons and colors
- Currency conversion based on user settings

Features to Develop:
- Edit expense functionality
- Monthly summary with comparisons
- Date range filtering
 */

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'addexpense.dart';
import '../models/expense.dart';
import '../database/database_helper.dart';
import '../screens/settings.dart';
import '../models/currency_helper.dart'; // Import the helper

class Expenses extends StatefulWidget {
  const Expenses({Key? key}) : super(key: key);

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Expense> _expenses = [];
  Map<String, double> _categoryTotals = {};
  double _totalSpending = 0.0;
  double _totalIncome = 0.0;
  bool _isLoading = true;
  String _displayCurrency = 'USD'; // Current display currency

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);

    await _debugDatabase();

    // Get the current display currency from settings
    final displayCurrency = await CurrencyHelper.getCurrentCurrency();
    print('Display Currency: $displayCurrency');

    final expenses = await _dbHelper.getAllExpenses();

    // Calculate totals manually by converting each expense individually
    double totalSpending = 0.0;
    Map<String, double> categoryTotals = {};

    for (var expense in expenses) {
      print('Converting: ${expense.amount} ${expense.currency} -> $displayCurrency');

      // Convert each expense amount to display currency
      final convertedAmount = CurrencyHelper.convert(
        amount: expense.amount,
        fromCurrency: expense.currency,
        toCurrency: displayCurrency,
      );

      print('Converted to: $convertedAmount $displayCurrency');

      // Add to total spending
      totalSpending += convertedAmount;

      // Add to category totals
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0.0) + convertedAmount;
    }

    print('Total Spending: $totalSpending $displayCurrency');
    print('Category Totals: $categoryTotals');

    // Get all incomes and convert them
    final incomes = await _dbHelper.getAllIncomes();
    double totalIncome = 0.0;

    for (var income in incomes) {
      final convertedAmount = CurrencyHelper.convert(
        amount: income.amount,
        fromCurrency: income.currency,
        toCurrency: displayCurrency,
      );
      totalIncome += convertedAmount;
    }

    setState(() {
      _expenses = expenses;
      _categoryTotals = categoryTotals;
      _totalSpending = totalSpending;
      _totalIncome = totalIncome;
      _displayCurrency = displayCurrency;
      _isLoading = false;
    });
  }

  Future<void> _debugDatabase() async {
    final db = await _dbHelper.database;
    print('DATABASE LOCATION: ${db.path}');
    print('━' * 60);

    final expenses = await _dbHelper.getAllExpenses();
    print('Total expenses in database: ${expenses.length}');

    if (expenses.isNotEmpty) {
      print('Expense List:');
      for (var expense in expenses) {
        print(
          '  • ${expense.category}: ${expense.currency} \$${expense.amount.toStringAsFixed(2)} on ${expense.date}',
        );
        if (expense.note != null) print('    Note: ${expense.note}');
      }
    } else {
      print('  (No expenses yet - add some using the + button!)');
    }
    print('━' * 60);
  }

  Future<void> _navigateToAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddExpense()),
    );
    _loadExpenses();
  }

  Future<void> _deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    _loadExpenses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    }
  }

  Color _getCategoryColor(String category) {
    const colors = {
      'Food': Colors.orange,
      'Shopping': Colors.purple,
      'Gas': Colors.blue,
      'Bills': Colors.red,
      'Entertainment': Colors.pink,
      'Healthcare': Colors.green,
      'Transportation': Colors.teal,
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      'Food': Icons.restaurant,
      'Shopping': Icons.shopping_bag,
      'Gas': Icons.local_gas_station,
      'Bills': Icons.receipt_long,
      'Entertainment': Icons.movie,
      'Healthcare': Icons.local_hospital,
      'Transportation': Icons.directions_bus,
      'Other': Icons.category,
    };
    return icons[category] ?? Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('images/track_ya_cash_img.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildTotalSpendingCard(),
            if (_categoryTotals.isNotEmpty) _buildPieChartSection(),
            _buildExpensesList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _navigateToAddExpense,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first expense',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalSpendingCard() {
    final incomeRemaining = _totalIncome - _totalSpending;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Spending',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyHelper.formatAmount(_totalSpending, _displayCurrency),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            Container(height: 60, width: 1, color: Colors.grey[300]),
            Expanded(
              child: Column(
                children: [
                  const Text(
                    'Remaining',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyHelper.formatAmount(incomeRemaining, _displayCurrency),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: incomeRemaining >= 0 ? Colors.blue : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChartSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    return _categoryTotals.entries.map((entry) {
      final percentage = (_categoryTotals[entry.key]! / _totalSpending) * 100;
      final amount = entry.value;

      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%\n${CurrencyHelper.formatAmount(amount, _displayCurrency)}',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: _categoryTotals.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getCategoryColor(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${entry.key}: ${CurrencyHelper.formatAmount(entry.value, _displayCurrency)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildExpensesList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Expenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _expenses.length,
            itemBuilder: (context, index) {
              final expense = _expenses[index];
              return _buildExpenseCard(expense);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final date = DateTime.parse(expense.date);

    // Convert expense amount to display currency
    final convertedAmount = CurrencyHelper.convert(
      amount: expense.amount,
      fromCurrency: expense.currency,
      toCurrency: _displayCurrency,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.category),
          child: Icon(_getCategoryIcon(expense.category), color: Colors.white),
        ),
        title: Text(
          expense.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormatter.format(date)),
            if (expense.note != null && expense.note!.isNotEmpty)
              Text(
                expense.note!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            // Show original currency if different from display currency
            if (expense.currency != _displayCurrency)
              Text(
                'Original: ${expense.currency} \$${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: Text(
          CurrencyHelper.formatAmount(convertedAmount, _displayCurrency),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Expense?'),
              content: const Text(
                'Are you sure you want to delete this expense?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteExpense(expense.id!);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}