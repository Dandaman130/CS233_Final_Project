/*
Allows users to add new expense entries with:
- Amount (required, numeric with decimal support)
- Category (dropdown selection from predefined categories)
- Date (date picker, defaults to today)
- Note (optional text field for additional context)
- Currency (dropdown, currently USD only, scalable to multiple currencies)

Features:
- Form validation for amount field
- Date picker integration
- Category icons in dropdown
- Loading state while saving
- Success/error feedback via SnackBar
- Auto-return to expenses screen after save
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For input formatters
import 'package:intl/intl.dart'; // For date formatting
import '../models/incomes.dart'; // Expense data model
import '../database/database_helper.dart'; // SQLite database helper

// Main AddIncome widget (StatefulWidget for form state management)
class AddIncome extends StatefulWidget {
  const AddIncome({Key? key}) : super(key: key);

  @override
  State<AddIncome> createState() => _AddIncomeState();
}

// State class for AddExpense - manages form data and submission
class _AddIncomeState extends State<AddIncome> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text editing controllers for input fields
  final _amountController = TextEditingController(); // Amount input
  final _noteController = TextEditingController(); // Note input

  // Form state variables
  String _selectedCategory = IncomeCategories.salary; // Default category
  DateTime _selectedDate = DateTime.now(); // Default to today
  String _selectedCurrency =
      'USD'; // Default currency, scalable to other currencies
  bool _isSaving = false; // Loading state during save operation

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final incomes = Incomes(
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate.toIso8601String().substring(0, 10), // YYYY-MM-DD
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        currency: _selectedCurrency,
      );

      try {
        await DatabaseHelper.instance.createIncome(incomes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Income added successfully!')),
          );
          Navigator.pop(context); // Return to income screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error saving income: $e')));
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('MMM dd, yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Income'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Field
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'),
                        ),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Please enter a valid amount';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                      ),
                      items: IncomeCategories.all.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(_getCategoryIcon(category), size: 20),
                              const SizedBox(width: 10),
                              Text(category),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 20),

                    // Date Picker
                    InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          dateFormatter.format(_selectedDate),
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Note Field (Optional)
                    TextFormField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Note (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        hintText: 'Add a note about this income',
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),
                    const SizedBox(height: 20),

                    // Currency Dropdown (currently only USD, scalable for future)
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                        // TODO: Add more currencies in the future
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCurrency = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 30),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveIncome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Save Income',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  IconData _getCategoryIcon(String category) {
    const icons = {
      'Salary': Icons.cases_rounded,
      'Self Employment': Icons.person,
      'Bonus': Icons.celebration_rounded,
      'Capital Gain': Icons.line_axis_rounded,
      'Other': Icons.category,
    };
    return icons[category] ?? Icons.category;
  }
}
