import 'package:shared_preferences/shared_preferences.dart';

class CurrencyHelper {
  // Exchange rates relative to USD (base currency)
  static const Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'JPY': 149.50,
    'GBP': 0.79,
  };

  // Currency symbols
  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'EUR': '€',
    'JPY': '¥',
    'GBP': '£',
  };

  /// Get the current selected currency from SharedPreferences
  static Future<String> getCurrentCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('currency') ?? 'USD';
  }

  /// Get the symbol for a currency code
  static String getSymbol(String currencyCode) {
    return _currencySymbols[currencyCode] ?? '\$';
  }

  /// Convert an amount from one currency to another
  /// IMPORTANT: Only converts if currencies are different
  static double convert({
    required double amount,
    required String fromCurrency,
    required String toCurrency,
  }) {
    // If currencies are the same, return the original amount
    if (fromCurrency == toCurrency) {
      return amount;
    }

    // Convert to USD first (if not already USD)
    double amountInUSD = amount / (_exchangeRates[fromCurrency] ?? 1.0);

    // Convert from USD to target currency
    double convertedAmount = amountInUSD * (_exchangeRates[toCurrency] ?? 1.0);

    return convertedAmount;
  }

  /// Format an amount with the appropriate currency symbol
  static String formatAmount(double amount, String currencyCode) {
    final symbol = getSymbol(currencyCode);

    // JPY typically doesn't use decimal places
    if (currencyCode == 'JPY') {
      return '$symbol${amount.toStringAsFixed(0)}';
    }

    return '$symbol${amount.toStringAsFixed(2)}';
  }
}