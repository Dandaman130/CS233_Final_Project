/*
This page will allow for users to enter their incomes. With each entry,
the app will keep track of the total amount of incomes that the user has
spent within the month, along with a breakdown of spending habits per category.

Features Implemented:
- Add income (via FAB button)
- Delete entries (long-press on income card)
- Categorical summary with pie chart
- Total spending calculation
- Chronological income list with icons and colors
- Currency conversion based on user settings

Features to Develop:
- Edit income functionality
- Monthly summary with comparisons
- Date range filtering
 */

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'addincome.dart';
import '../models/incomes.dart';
import '../database/database_helper.dart';
import '../screens/settings.dart';
import '../models/currency_helper.dart'; // Import the helper

class Income extends StatefulWidget {
  const Income({Key? key}) : super(key: key);

  @override
  State<Income> createState() => _IncomeState();
}

class _IncomeState extends State<Income> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Incomes> _income = [];
  Map<String, double> _categoryTotals = {};
  double _totalEarnings = 0.0;
  bool _isLoading = true;
  String _displayCurrency = 'USD'; // Current display currency

  @override
  void initState() {
    super.initState();
    _loadIncomes();
  }

  Future<void> _loadIncomes() async {
    setState(() => _isLoading = true);

    await _debugDatabase();

    // Get the current display currency from settings
    final displayCurrency = await CurrencyHelper.getCurrentCurrency();

    final income = await _dbHelper.getAllIncomes();

    // Calculate totals manually by converting each income individually
    double totalEarnings = 0.0;
    Map<String, double> categoryTotals = {};

    for (var inc in income) {
      // Convert each income amount to display currency
      final convertedAmount = CurrencyHelper.convert(
        amount: inc.amount,
        fromCurrency: inc.currency,
        toCurrency: displayCurrency,
      );

      // Add to total earnings
      totalEarnings += convertedAmount;

      // Add to category totals
      categoryTotals[inc.category] =
          (categoryTotals[inc.category] ?? 0.0) + convertedAmount;
    }

    setState(() {
      _income = income;
      _categoryTotals = categoryTotals;
      _totalEarnings = totalEarnings;
      _displayCurrency = displayCurrency;
      _isLoading = false;
    });
  }

  Future<void> _debugDatabase() async {
    final db = await _dbHelper.database;
    print('DATABASE LOCATION: ${db.path}');
    print('━' * 60);

    final incomes = await _dbHelper.getAllIncomes();
    print('Total incomes in database: ${incomes.length}');

    if (incomes.isNotEmpty) {
      print('Income List:');
      for (var income in incomes) {
        print(
          '  • ${income.category}: ${income.currency} \$${income.amount.toStringAsFixed(2)} on ${income.date}',
        );
        if (income.note != null) print('    Note: ${income.note}');
      }
    } else {
      print('  (No incomes yet - add some using the + button!)');
    }
    print('━' * 60);
  }

  Future<void> _navigateToAddIncome() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddIncome()),
    );
    _loadIncomes();
  }

  Future<void> _deleteIncome(int id) async {
    await _dbHelper.deleteIncome(id);
    _loadIncomes();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income deleted')),
      );
    }
  }

  Color _getCategoryColor(String category) {
    const colors = {
      'Salary': Colors.orange,
      'Self Employment': Colors.purple,
      'Bonus': Colors.blue,
      'Capital Gain': Colors.red,
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      'Salary': Icons.attach_money_rounded,
      'Self Employment': Icons.person,
      'Bonus': Icons.card_giftcard_rounded,
      'Capital Gain': Icons.line_axis_rounded,
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
          : _income.isEmpty
          ? _buildEmptyState()
          : SingleChildScrollView(
        child: Column(
          children: [
            _buildTotalEarningsCard(),
            if (_categoryTotals.isNotEmpty) _buildPieChartSection(),
            _buildIncomeList(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _navigateToAddIncome,
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
            'No incomes yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first income',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalEarningsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Total Earnings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyHelper.formatAmount(_totalEarnings, _displayCurrency),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All time',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              'Earnings by Category',
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
      final percentage = (_categoryTotals[entry.key]! / _totalEarnings) * 100;
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

  Widget _buildIncomeList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Income',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _income.length,
            itemBuilder: (context, index) {
              final income = _income[index];
              return _buildIncomeCard(income);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeCard(Incomes incomes) {
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final date = DateTime.parse(incomes.date);

    // Convert income amount to display currency
    final convertedAmount = CurrencyHelper.convert(
      amount: incomes.amount,
      fromCurrency: incomes.currency,
      toCurrency: _displayCurrency,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(incomes.category),
          child: Icon(_getCategoryIcon(incomes.category), color: Colors.white),
        ),
        title: Text(
          incomes.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormatter.format(date)),
            if (incomes.note != null && incomes.note!.isNotEmpty)
              Text(
                incomes.note!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            // Show original currency if different from display currency
            if (incomes.currency != _displayCurrency)
              Text(
                'Original: ${incomes.currency} \$${incomes.amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: Text(
          CurrencyHelper.formatAmount(convertedAmount, _displayCurrency),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Income?'),
              content: const Text(
                'Are you sure you want to delete this income?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteIncome(incomes.id!);
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