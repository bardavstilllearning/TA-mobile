import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../widgets/custom_snackbar.dart';
import '../../services/api_service.dart';
import '../start_page.dart';
import '../../utils/helpers/currency_helper.dart';
import '../../utils/user_preferences.dart';
import '../../utils/helpers/timezone_helper.dart';

class OrderPage extends StatefulWidget {
  final Map<String, dynamic> worker;

  const OrderPage({
    super.key,
    required this.worker,
  });

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  DateTime? selectedDate;
  String? selectedSession;
  bool isSubmitting = false;
  String currentCurrency = 'IDR'; // ✅ Add this
  String currentTimezone = 'Asia/Jakarta';

  List<String> availableTimeslots = [
    "08:00-10:00",
    "10:00-12:00",
    "13:00-15:00",
    "15:00-17:00",
  ];

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null);
    _loadPreferences(); // ✅ Load both
  }

  // ✅ NEW: Load currency & timezone
  Future<void> _loadPreferences() async {
    final currency = await UserPreferences.getCurrency();
    final timezone = await UserPreferences.getTimezone();
    setState(() {
      currentCurrency = currency;
      currentTimezone = timezone;
    });
  }

  List<String> get convertedTimeslots {
    return availableTimeslots.map((slot) {
      return TimezoneHelper.convertTime(slot, currentTimezone);
    }).toList();
  }

  // ✅ UPDATED: Format dengan currency preference
  String formatCurrency(dynamic harga) {
    return CurrencyHelper.convertAndFormat(harga, currentCurrency);
  }

  Future<void> _submitOrder() async {
    if (selectedDate == null) {
      CustomSnackbar.show(
        context,
        message: "Pilih tanggal terlebih dahulu!",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (selectedSession == null) {
      CustomSnackbar.show(
        context,
        message: "Pilih sesi waktu terlebih dahulu!",
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final response = await ApiService.createOrder(
        workerId: widget.worker['id'],
        orderDate: DateFormat('yyyy-MM-dd').format(selectedDate!),
        timeSlot: selectedSession!,
      );

      if (response['success'] == true) {
        if (mounted) {
          CustomSnackbar.show(
            context,
            message: "Pesanan berhasil dibuat!",
            backgroundColor: Colors.green,
          );

          Future.delayed(const Duration(seconds: 1), () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePage(initialIndex: 2),
              ),
              (route) => false,
            );
          });
        }
      } else {
        throw response['message'] ?? 'Gagal membuat pesanan';
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Error: $e!',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final worker = widget.worker;
    double pricePerHour =
        double.tryParse(worker['price_per_hour'].toString()) ?? 0;
    double total = pricePerHour * 2;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Konfirmasi Pesanan",
          style: TextStyle(
            color: Color(0xFF4A70A9),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF4A70A9),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              worker['name'] ?? 'Worker',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              worker['job_title'] ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            const Divider(height: 32),

            // ✅ Show current timezone
            Text(
              'Jam sekarang: ${TimezoneHelper.getCurrentTimeInTimezone(currentTimezone)}',
              style: const TextStyle(fontSize: 12, fontFamily: 'Poppins'),
            ),
            const SizedBox(height: 16),

            // Tanggal
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: const Text(
                  "Tanggal Tersedia",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    selectedDate == null
                        ? "Belum dipilih"
                        : DateFormat('EEEE, dd MMMM yyyy', 'id_ID')
                            .format(selectedDate!),
                  ),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 14)),
                    locale: const Locale('id', 'ID'), // ✅ Locale Indonesia
                  );
                  if (pickedDate != null) {
                    setState(() {
                      selectedDate = pickedDate;
                      selectedSession = null;
                    });
                  }
                },
              ),
            ),

            // Sesi waktu
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: const Text(
                  "Pilih Sesi Tersedia",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: convertedTimeslots.map((sesi) {
                      return ChoiceChip(
                        label: Text(sesi),
                        selected: selectedSession == sesi,
                        selectedColor: const Color(0xFF4A70A9),
                        labelStyle: TextStyle(
                          color: selectedSession == sesi
                              ? Colors.white
                              : Colors.black,
                        ),
                        onSelected: (_) {
                          setState(() {
                            selectedSession = sesi;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const Spacer(),

            // Info harga
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Jarak Pekerja"),
                Text("${worker['distance']?.toString() ?? '0'} km"),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Harga",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  formatCurrency(total), // ✅ Use formatted currency
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A70A9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(isSubmitting ? "Memproses..." : "Konfirmasi Pesanan"),
              onPressed: isSubmitting ? null : _submitOrder,
            ),
          ),
        ),
      ),
    );
  }
}
