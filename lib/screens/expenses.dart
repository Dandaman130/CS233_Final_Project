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

Features to Develop:
- Edit expense functionality
- Monthly summary with comparisons
- Date range filtering
 */

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Package for pie chart visualization
import 'package:intl/intl.dart'; // Package for date formatting
import 'addexpense.dart'; // Screen for adding new expenses
import '../models/expense.dart'; // Expense data model
import '../database/database_helper.dart'; // SQLite database helper

// Main Expenses widget (StatefulWidget for dynamic data)
class Expenses extends StatefulWidget {
  const Expenses({Key? key}) : super(key: key);

  @override
  State<Expenses> createState() => _ExpensesState();
}

// State class for Expenses - manages data and UI updates
class _ExpensesState extends State<Expenses> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // State variables to hold expense data
  List<Expense> _expenses = []; // List of all expenses
  Map<String, double> _categoryTotals = {}; // Total spending per category
  double _totalSpending = 0.0; // Grand total of all expenses
  bool _isLoading = true; // Loading state for async operations

  // Start up
  @override
  void initState() {
    super.initState();
    _loadExpenses(); // Load expenses from database on startup
  }

  // Load all expenses from database and calculate totals
  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);

    // DEBUG: Print database location and contents to console
    await _debugDatabase();

    // Fetch all expenses from database (sorted by date, most recent first)
    final expenses = await _dbHelper.getAllExpenses();
    // TODO: To filter by current month only

    // Get spending totals grouped by category (for pie chart)
    final categoryTotals = await _dbHelper.getSpendingByCategory();

    // Get grand total of all expenses
    final total = await _dbHelper.getTotalSpending();

    // Update UI with fetched data
    setState(() {
      _expenses = expenses;
      _categoryTotals = categoryTotals;
      _totalSpending = total;
      _isLoading = false; // Hide loading indicator
    });
  }

  // Debug method to print database info to console (for dev)
  // Prints: database path, expense count, and list of all expenses
  Future<void> _debugDatabase() async {
    final db = await _dbHelper.database;
    print('DATABASE LOCATION: ${db.path}');
    print('━' * 60);

    final expenses = await _dbHelper.getAllExpenses();
    print('Total expenses in database: ${expenses.length}');

    if (expenses.isNotEmpty) {
      print('Expense List:');
      for (var expense in expenses) {
        print('  • ${expense.category}: ${expense.currency} \$${expense.amount.toStringAsFixed(2)} on ${expense.date}');
        if (expense.note != null) print('    Note: ${expense.note}');
      }
    } else {
      print('  (No expenses yet - add some using the + button!)');
    }
    print('━' * 60);
  }

  // Navigate to Add Expense screen and refresh data on return
  // Called when Floating Action Button is pressed
  Future<void> _navigateToAddExpense() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddExpense(),
      ),
    );
    // Refresh expenses list after returning (in case new expense was added)
    _loadExpenses();
  }

  // Delete an expense from database by ID
  // Shows confirmation snackbar after deletion
  Future<void> _deleteExpense(int id) async {
    await _dbHelper.deleteExpense(id);
    _loadExpenses(); // Reload data to reflect deletion
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    }
  }

  // Get the color associated with each category (for UI consistency)
  // Used in: pie chart, category icons, and legend
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
    return colors[category] ?? Colors.grey; // Default to grey if category not found
  }

  // Get the icon associated with each category
  // Used in: expense cards and category dropdown
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
    return icons[category] ?? Icons.category; // Default to category icon if not found
  }

  // Main build method - constructs the UI
  // Three possible states: loading, empty, or displaying expenses
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with title
      appBar: AppBar(
        title: const Text('Expenses'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _expenses.isEmpty
              ? _buildEmptyState() // Show "no expenses" message if empty
              : SingleChildScrollView( // Show expense data if available
                  child: Column(
                    children: [
                      // Total Spending Card - displays grand total
                      _buildTotalSpendingCard(),

                      // Pie Chart Section - visual breakdown by category
                      // Only shown if there are categorized expenses
                      if (_categoryTotals.isNotEmpty) _buildPieChartSection(),

                      // Expenses List - chronological list of all expenses
                      _buildExpensesList(),
                    ],
                  ),
                ),

      // Navigates to Add Expense screen
      floatingActionButton: FloatingActionButton.small(
        onPressed: _navigateToAddExpense,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build empty state widget
  // Shown when no expenses exist in database
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large icon for visual emphasis
          Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),

          // Main message
          Text(
            'No expenses yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          // Guides user to add first expense
          Text(
            'Tap + to add your first expense',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Build total spending card widget
  // Displays the sum of all expenses in a prominent card
  Widget _buildTotalSpendingCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card title
            const Text(
              'Total Spending',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // Large total amount in red (expense color)
            Text(
              '\$${_totalSpending.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 4),

            // Time period label
            Text(
              'All time',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Build pie chart section widget
  // Displays visual breakdown of spending by category with legend
  Widget _buildPieChartSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section title
            const Text(
              'Spending by Category',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Pie chart visualization
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(), // Generate chart sections
                  sectionsSpace: 2, // Space between pie slices
                  centerSpaceRadius: 40, // Donut hole radius
                  borderData: FlBorderData(show: false), // No outer border
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Legend showing category colors and totals
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  // Build pie chart sections from category totals
  // Each section represents one expense category with color and percentage
  List<PieChartSectionData> _buildPieChartSections() {
    return _categoryTotals.entries.map((entry) {
      // Calculate percentage of total for this category
      final percentage = (_categoryTotals[entry.key]! / _totalSpending) * 100;

      return PieChartSectionData(
        color: _getCategoryColor(entry.key), // Category-specific color
        value: entry.value, // Actual spending amount (determines slice size)
        title: '${percentage.toStringAsFixed(1)}%', // Display percentage on slice
        radius: 80, // Slice radius (thickness)
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white, // White text for contrast
        ),
      );
    }).toList();
  }

  // Build legend widget
  // Shows colored circles with category names and amounts
  Widget _buildLegend() {
    return Wrap(
      spacing: 16, // Horizontal spacing between items
      runSpacing: 8, // Vertical spacing between rows
      children: _categoryTotals.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min, // Shrink to fit content
          children: [
            // Colored circle indicator (matches pie chart color)
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _getCategoryColor(entry.key),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),

            // Category name and total amount
            Text(
              '${entry.key}: \$${entry.value.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  // Build expenses list widget
  // Displays all expenses in a scrollable list using ListView.builder
  Widget _buildExpensesList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Text(
            'Recent Expenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // List of expense cards
          // Using ListView.builder for efficient rendering of large lists
          ListView.builder(
            shrinkWrap: true, // Let ListView size itself based on children
            physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling (parent ScrollView handles it)
            itemCount: _expenses.length, // Number of items to display
            itemBuilder: (context, index) {
              final expense = _expenses[index];
              return _buildExpenseCard(expense); // Build card for each expense
            },
          ),
        ],
      ),
    );
  }

  // Build individual expense card widget
  // Displays expense details in a card with long-press delete functionality
  Widget _buildExpenseCard(Expense expense) {
    // Date formatter for displaying dates in readable format (e.g., "Dec 07, 2024")
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final date = DateTime.parse(expense.date); // Parse ISO date string

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        // Left side: Category icon in colored circle
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(expense.category),
          child: Icon(_getCategoryIcon(expense.category), color: Colors.white),
        ),

        // Main content: Category name and details
        title: Text(
          expense.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        // Subtitle: Date and optional note
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formatted date
            Text(dateFormatter.format(date)),

            // Optional note (only shown if note exists and is not empty)
            if (expense.note != null && expense.note!.isNotEmpty)
              Text(
                expense.note!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),

        // Right side: Amount with currency
        trailing: Text(
          '${expense.currency} \$${expense.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red, // Red color emphasizes expense (money going out)
          ),
        ),

        // Long-press handler: Show delete confirmation dialog
        // TODO: Add edit functionality here as well
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Expense?'),
              content: const Text('Are you sure you want to delete this expense?'),
              actions: [
                // Cancel button
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),

                // Delete button (red to indicate destructive action)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    _deleteExpense(expense.id!); // Delete expense from database
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}