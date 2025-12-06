/*
This page will use pretty similar logic to what the expenses.dart file entails.
The main difference between the two is that this page will track any income
entries that the user adds. Expenses should take into account the amount of
income that the user has. If the user has more expenses than income, the value
should be negative.

Features:
- Add income
- Allow for users to edit/delete entries
- Anything else we can think of
- (We could add the monthly/categorical charts if we want, but since the main
feature of the app is tracking expenses, we can add it here only if we feel
the need to do so.
 */

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; //Package to implement chart

class AddExpense extends StatelessWidget {
  const AddExpense({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: const Center(
        child: Text('Add Expense'),
      ),
    );
  }
}