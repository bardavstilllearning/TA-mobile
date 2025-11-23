class CurrencyHelper {
  // Exchange rates terhadap IDR
  static Map<String, double> exchangeRates = {
    'IDR': 1.0,
    'USD': 0.000064,
    'EUR': 0.000059,
    'SGD': 0.000086,
    'MYR': 0.00030,
    'JPY': 0.0095,
  };

  static Map<String, String> currencySymbols = {
    'IDR': 'Rp',
    'USD': '\$',
    'EUR': '€',
    'SGD': 'S\$',
    'MYR': 'RM',
    'JPY': '¥',
  };

  // ✅ FIX: Parsing lebih robust
  static String convertAndFormat(dynamic amount, String targetCurrency) {
    int amountIDR;

    try {
      if (amount is int) {
        amountIDR = amount;
      } else if (amount is double) {
        amountIDR = amount.toInt();
      } else if (amount is String) {
        // Buang semua karakter non-numeric kecuali titik
        final cleaned = amount.replaceAll(RegExp(r'[^0-9.]'), '');
        amountIDR = double.tryParse(cleaned)?.toInt() ?? 0;
      } else {
        amountIDR = 0;
      }
    } catch (e) {
      print('❌ Currency parsing error: $e');
      amountIDR = 0;
    }

    if (amountIDR == 0) {
      final symbol = currencySymbols[targetCurrency] ?? '';
      return '$symbol 0';
    }

    final rate = exchangeRates[targetCurrency] ?? 1.0;
    final converted = (amountIDR * rate);
    final symbol = currencySymbols[targetCurrency] ?? '';

    if (targetCurrency == 'IDR') {
      final formatted = amountIDR.toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]}.',
          );
      return '$symbol $formatted';
    } else if (targetCurrency == 'JPY') {
      final formatted = converted.toInt().toString().replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
            (Match m) => '${m[1]},',
          );
      return '$symbol $formatted';
    } else {
      final formatted = converted.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+\.)'),
            (Match m) => '${m[1]},',
          );
      return '$symbol $formatted';
    }
  }

  // ✅ NEW: Parse amount to int
  static int parseAmount(dynamic amount) {
    try {
      if (amount is int) return amount;
      if (amount is double) return amount.toInt();
      if (amount is String) {
        final cleaned = amount.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned)?.toInt() ?? 0;
      }
      return 0;
    } catch (e) {
      print('❌ Amount parsing error: $e');
      return 0;
    }
  }
}
