import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';

class Settings extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  Settings({
    Key? key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  }) : super(key: key);

  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  String _selectedCurrency = "USD"; // Default currency
  bool _isLoading = true; // Add loading state

  // Define available currencies
  static const List<String> _availableCurrencies = ['USD', 'EUR', 'JPY', 'GBP'];

  @override
  void initState() {
    super.initState();
    _loadCurrency(); // Load saved currency when screen opens
  }

  Future<void> _loadCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCurrency = prefs.getString('currency') ?? 'USD';

      // Validate that the saved currency is in our available list
      if (mounted) {
        setState(() {
          _selectedCurrency = _availableCurrencies.contains(savedCurrency)
              ? savedCurrency
              : 'USD';
          _isLoading = false;
        });
      }
    } catch (e) {
      // If SharedPreferences fails, just use default USD
      print('Error loading currency: $e');
      if (mounted) {
        setState(() {
          _selectedCurrency = 'USD';
          _isLoading = false;
        });
      }
    }
  }

  void _saveCurrency(String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currency', value);
    } catch (e) {
      print('Error saving currency: $e');
    }
  }

  void _showClearDatabaseDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Database'),
          content: const Text(
            'Are you sure you want to clear all expenses and income data? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _clearDatabase(); // Clear the database
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _clearDatabase() async {
    try {
      // Clear all expenses and incomes from database
      await DatabaseHelper.instance.clearAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database cleared successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error clearing database: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error clearing database: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          : ListView(
              children: [
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  value: widget.isDarkMode,
                  onChanged: widget.onDarkModeChanged,
                  secondary: const Icon(Icons.nightlight_round),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DropdownButtonFormField<String>(
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
                      DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                      DropdownMenuItem(value: 'JPY', child: Text('JPY (¥)')),
                      DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCurrency = value!;
                      });
                      _saveCurrency(value!); // Save choice persistently
                    },
                  ),
                ),
                // Clear Database Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showClearDatabaseDialog,
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Clear Database'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
