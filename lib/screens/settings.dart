/*
This page will act as the settings for the app. Because of our time frame,
the settings for the app should be basic and not include too many features
(unless we have time of course)

Features:
- Set the currency type (Euro, peso, yen, etc.)
- Dark Mode toggle
- Date Persistence (Making sure user info is saved after app is closed)
 */

import 'package:flutter/material.dart';

class Settings extends StatelessWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onDarkModeChanged;

  const Settings({
    Key? key,
    required this.isDarkMode,
    required this.onDarkModeChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: isDarkMode,
            onChanged: onDarkModeChanged,
            secondary: const Icon(Icons.nightlight_round),
          ),
        ],
      ),
    );
  }
}
