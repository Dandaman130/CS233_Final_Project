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

Features to Develop:
- Edit income functionality
- Monthly summary with comparisons
- Date range filtering
 */

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // Package for pie chart visualization
import 'package:intl/intl.dart'; // Package for date formatting
import 'addincome.dart'; // Screen for adding new incomes
import '../models/incomes.dart'; // Income data model
import '../database/database_helper.dart'; // SQLite database helper

// Main Incomes widget (StatefulWidget for dynamic data)
class Income extends StatefulWidget {
  const Income({Key? key}) : super(key: key);

  @override
  State<Income> createState() => _IncomeState();
}

// State class for Incomes - manages data and UI updates
class _IncomeState extends State<Income> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // State variables to hold income data
  List<Incomes> _income = []; // List of all incomes
  Map<String, double> _categoryTotals = {}; // Total spending per category
  double _totalEarnings = 0.0; // Grand total of all incomes
  bool _isLoading = true; // Loading state for async operations

  // Start up
  @override
  void initState() {
    super.initState();
    _loadIncomes(); // Load incomes from database on startup
  }

  // Load all incomes from database and calculate totals
  Future<void> _loadIncomes() async {
    setState(() => _isLoading = true);

    // DEBUG: Print database location and contents to console
    await _debugDatabase();

    // Fetch all incomes from database (sorted by date, most recent first)
    final income = await _dbHelper.getAllIncomes();
    // TODO: To filter by current month only

    // Get spending totals grouped by category (for pie chart)
    final categoryTotals = await _dbHelper.getIncomeByCategory();

    // Get grand total of all incomes
    final total = await _dbHelper.getTotalIncome();

    // Update UI with fetched data
    setState(() {
      _income = income;
      _categoryTotals = categoryTotals;
      _totalEarnings = total;
      _isLoading = false; // Hide loading indicator
    });
  }

  // Debug method to print database info to console (for dev)
  // Prints: database path, income count, and list of all incomes
  Future<void> _debugDatabase() async {
    final db = await _dbHelper.database;
    print('DATABASE LOCATION: ${db.path}');
    print('━' * 60);

    final incomes = await _dbHelper.getAllIncomes();
    print('Total incomes in database: ${incomes.length}');

    if (incomes.isNotEmpty) {
      print('Income List:');
      for (var income in incomes) {
        print('  • ${income.category}: ${income.currency} \$${income.amount.toStringAsFixed(2)} on ${income.date}');
        if (income.note != null) print('    Note: ${income.note}');
      }
    } else {
      print('  (No incomes yet - add some using the + button!)');
    }
    print('━' * 60);
  }

  // Navigate to Add Income screen and refresh data on return
  // Called when Floating Action Button is pressed
  Future<void> _navigateToAddIncome() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddIncome(),
      ),
    );
    // Refresh incomes list after returning (in case new income was added)
    _loadIncomes();
  }

  // Delete an income from database by ID
  // Shows confirmation snackbar after deletion
  Future<void> _deleteIncome(int id) async {
    await _dbHelper.deleteIncome(id);
    _loadIncomes(); // Reload data to reflect deletion
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Income deleted')),
      );
    }
  }

  // Get the color associated with each category (for UI consistency)
  // Used in: pie chart, category icons, and legend
  Color _getCategoryColor(String category) {
    const colors = {
      'Salary': Colors.orange,
      'Self Employment': Colors.purple,
      'Bonus': Colors.blue,
      'Capital Gain': Colors.red,
      'Other': Colors.grey,
    };
    return colors[category] ?? Colors.grey; // Default to grey if category not found
  }

  // Get the icon associated with each category
  // Used in: income cards and category dropdown
  IconData _getCategoryIcon(String category) {
    const icons = {
      'Salary': Icons.cases_rounded,
      'Self Employment': Icons.person,
      'Bonus': Icons.celebration_rounded,
      'Capital Gain': Icons.line_axis_rounded,
      'Other': Icons.category,
    };
    return icons[category] ?? Icons.category; // Default to category icon if not found
  }

  // Main build method - constructs the UI
  // Three possible states: loading, empty, or displaying incomes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with title
      appBar: AppBar(
        title: const Text('Incomes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _income.isEmpty
          ? _buildEmptyState() // Show "no incomes" message if empty
          : SingleChildScrollView( // Show incomes data if available
        child: Column(
          children: [
            // Total Earnings Card - displays grand total
            _buildTotalEarningsCard(),

            // Pie Chart Section - visual breakdown by category
            // Only shown if there are categorized incomes
            if (_categoryTotals.isNotEmpty) _buildPieChartSection(),

            // Incomes List - chronological list of all incomes
            _buildIncomeList(),
          ],
        ),
      ),

      // Navigates to Add Income screen
      floatingActionButton: FloatingActionButton.small(
        onPressed: _navigateToAddIncome,
        child: const Icon(Icons.add),
      ),
    );
  }

  // Build empty state widget
  // Shown when no incomes exist in database
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
            'No incomes yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),

          // Guides user to add first income
          Text(
            'Tap + to add your first income',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // Build total earnings card widget
  // Displays the sum of all incomes in a prominent card
  Widget _buildTotalEarningsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Card title
            const Text(
              'Total Earnings',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),

            // Large total amount in red (income color)
            Text(
              '\$${_totalEarnings.toStringAsFixed(2)}',
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
              'Earnings by Category',
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
  // Each section represents one income category with color and percentage
  List<PieChartSectionData> _buildPieChartSections() {
    return _categoryTotals.entries.map((entry) {
      // Calculate percentage of total for this category
      final percentage = (_categoryTotals[entry.key]! / _totalEarnings) * 100;

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

  // Build income list widget
  // Displays all incomes in a scrollable list using ListView.builder
  Widget _buildIncomeList() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          const Text(
            'Recent Income',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // List of income cards
          // Using ListView.builder for efficient rendering of large lists
          ListView.builder(
            shrinkWrap: true, // Let ListView size itself based on children
            physics: const NeverScrollableScrollPhysics(), // Disable internal scrolling (parent ScrollView handles it)
            itemCount: _income.length, // Number of items to display
            itemBuilder: (context, index) {
              final income = _income[index];
              return _buildIncomeCard(income); // Build card for each income
            },
          ),
        ],
      ),
    );
  }

  // Build individual income card widget
  // Displays income details in a card with long-press delete functionality
  Widget _buildIncomeCard(Incomes incomes) {
    // Date formatter for displaying dates in readable format (e.g., "Dec 07, 2024")
    final dateFormatter = DateFormat('MMM dd, yyyy');
    final date = DateTime.parse(incomes.date); // Parse ISO date string

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        // Left side: Category icon in colored circle
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(incomes.category),
          child: Icon(_getCategoryIcon(incomes.category), color: Colors.white),
        ),

        // Main content: Category name and details
        title: Text(
          incomes.category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        // Subtitle: Date and optional note
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formatted date
            Text(dateFormatter.format(date)),

            // Optional note (only shown if note exists and is not empty)
            if (incomes.note != null && incomes.note!.isNotEmpty)
              Text(
                incomes.note!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),

        // Right side: Amount with currency
        trailing: Text(
          '${incomes.currency} \$${incomes.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.red, // Red color emphasizes income (money going out)
          ),
        ),

        // Long-press handler: Show delete confirmation dialog
        // TODO: Add edit functionality here as well
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Income?'),
              content: const Text('Are you sure you want to delete this income?'),
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
                    _deleteIncome(incomes.id!); // Delete income from database
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