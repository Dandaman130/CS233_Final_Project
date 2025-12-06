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
  const Settings({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: const Center(
        child: Text('Settings'),
      ),
    );
  }
}