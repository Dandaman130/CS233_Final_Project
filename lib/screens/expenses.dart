/*
This page will allow for users to enter their expenses. With each entry,
the app will keep track of the total amount of expenses that the user has
spent within the month, along with a breakdown of spending habits per category.

Features to Develop:
- Add expenses
- Allow for users to edit/delete entries
- Give a categorical summary of spendings
- Give a monthly summary of spendings
- Anything else we can think of
 */

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; //Package to implement chart
import 'addexpense.dart';

class Expenses extends StatelessWidget {
  const Expenses({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: const Center(
        child: Text('Expenses'),
      ),
        floatingActionButton: FloatingActionButton.small(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddExpense(),
              ),
            );
          },
          child: const Icon(Icons.add),
        ),
    );
  }
}