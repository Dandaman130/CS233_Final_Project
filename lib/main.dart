import 'package:flutter/material.dart';
import 'screens/expenses.dart';
import 'screens/income.dart';
import 'screens/settings.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Home(
        isDarkMode: _isDarkMode,
        onDarkModeChanged: _toggleDarkMode,
      ),
    );
  }
}

class Home extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const Home({
    Key? key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  }) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const Expenses(),
      const Income(),
      Settings(
        isDarkMode: widget.isDarkMode,
        onDarkModeChanged: widget.onDarkModeChanged,
      ),
    ];

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.payment_outlined),
            label: "Expenses",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money_outlined),
            label: "Income",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Settings",
          ),
        ],
      ),
    );
  }
}
