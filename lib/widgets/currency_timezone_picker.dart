import 'package:flutter/material.dart';

class CurrencyData {
  final String code;
  final String name;
  final String flag;
  final String symbol;

  const CurrencyData({
    required this.code,
    required this.name,
    required this.flag,
    required this.symbol,
  });
}

class TimezoneData {
  final String code;
  final String name;
  final String label;
  final String flag;
  final Color color;

  const TimezoneData({
    required this.code,
    required this.name,
    required this.label,
    required this.flag,
    required this.color,
  });
}

const List<CurrencyData> currencies = [
  CurrencyData(
      code: 'IDR', name: 'Indonesian Rupiah', flag: '🇮🇩', symbol: 'Rp'),
  CurrencyData(code: 'USD', name: 'US Dollar', flag: '🇺🇸', symbol: '\$'),
  CurrencyData(code: 'EUR', name: 'Euro', flag: '🇪🇺', symbol: '€'),
  CurrencyData(
      code: 'SGD', name: 'Singapore Dollar', flag: '🇸🇬', symbol: 'S\$'),
  CurrencyData(
      code: 'MYR', name: 'Malaysian Ringgit', flag: '🇲🇾', symbol: 'RM'),
  CurrencyData(code: 'JPY', name: 'Japanese Yen', flag: '🇯🇵', symbol: '¥'),
];

const List<TimezoneData> timezones = [
  TimezoneData(
    code: 'Asia/Jakarta',
    name: 'Indonesia (Jakarta)',
    label: 'WIB (UTC+7)',
    flag: '🇮🇩',
    color: Color(0xFFFF0000),
  ),
  TimezoneData(
    code: 'Asia/Makassar',
    name: 'Indonesia (Makassar)',
    label: 'WITA (UTC+8)',
    flag: '🇮🇩',
    color: Color(0xFFFF0000),
  ),
  TimezoneData(
    code: 'Asia/Jayapura',
    name: 'Indonesia (Jayapura)',
    label: 'WIT (UTC+9)',
    flag: '🇮🇩',
    color: Color(0xFFFF0000),
  ),
  TimezoneData(
    code: 'America/New_York',
    name: 'United States',
    label: 'EST (UTC-5)',
    flag: '🇺🇸',
    color: Color(0xFF3C3B6E),
  ),
  TimezoneData(
    code: 'Europe/London',
    name: 'United Kingdom',
    label: 'GMT (UTC+0)',
    flag: '🇬🇧',
    color: Color(0xFF012169),
  ),
];

void showCurrencyPicker({
  required BuildContext context,
  required String currentCurrency,
  required Function(String) onCurrencySelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4A70A9).withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A70A9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.attach_money_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Mata Uang',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A70A9),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Harga akan ditampilkan dalam mata uang terpilih',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: currencies.length,
              itemBuilder: (context, index) {
                final currency = currencies[index];
                final isSelected = currentCurrency == currency.code;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4A70A9).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4A70A9)
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4A70A9).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: ListTile(
                    onTap: () {
                      onCurrencySelected(currency.code);
                      Navigator.pop(context);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4A70A9)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          currency.flag,
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    title: Text(
                      currency.name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                        color: isSelected
                            ? const Color(0xFF4A70A9)
                            : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      '${currency.code} (${currency.symbol})',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color:
                            isSelected ? const Color(0xFF4A70A9) : Colors.grey,
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4A70A9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                        : Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

void showTimezonePicker({
  required BuildContext context,
  required String currentTimezone,
  required Function(String) onTimezoneSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4A70A9).withOpacity(0.05),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A70A9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Zona Waktu',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF4A70A9),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Waktu akan disesuaikan dengan zona terpilih',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: timezones.length,
              itemBuilder: (context, index) {
                final timezone = timezones[index];
                final isSelected = currentTimezone == timezone.code;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF4A70A9).withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF4A70A9)
                          : Colors.grey.shade200,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: const Color(0xFF4A70A9).withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: ListTile(
                    onTap: () {
                      onTimezoneSelected(timezone.code);
                      Navigator.pop(context);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4A70A9)
                            : timezone.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          timezone.flag, // ✅ Show flag emoji
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    ),
                    title: Text(
                      timezone.name,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                        color: isSelected
                            ? const Color(0xFF4A70A9)
                            : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      timezone.label,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color:
                            isSelected ? const Color(0xFF4A70A9) : Colors.grey,
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFF4A70A9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          )
                        : Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey.shade300,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
