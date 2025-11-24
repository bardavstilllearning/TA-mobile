import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/helpers/currency_helper.dart';
import '../../utils/helpers/image_helper.dart';
import '../../utils/helpers/timezone_helper.dart';
import '../../utils/user_preferences.dart';
import 'detail/order_detail_page.dart';

class ActivityPage extends StatefulWidget {
  const ActivityPage({super.key});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String currentCurrency = 'IDR';
  String currentTimezone = 'Asia/Jakarta';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadCurrency(),
      _loadTimezone(),
      _loadOrders(),
    ]);
  }

  Future<void> _loadCurrency() async {
    final currency = await UserPreferences.getCurrency();
    if (mounted) {
      setState(() => currentCurrency = currency);
    }
  }

  Future<void> _loadTimezone() async {
    final timezone = await UserPreferences.getTimezone();
    if (mounted) {
      setState(() => currentTimezone = timezone);
    }
  }

  Future<void> _loadOrders() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.getUserOrders();

      if (response['success'] == true && mounted) {
        setState(() {
          orders = List<Map<String, dynamic>>.from(response['orders'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading orders: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'accepted':
        return 'Diterima';
      case 'on_the_way':
        return 'Sedang Menuju Lokasi';
      case 'in_progress':
        return 'Sedang Bekerja';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'on_the_way':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatCurrency(dynamic amount) {
    return CurrencyHelper.convertAndFormat(amount, currentCurrency);
  }

  String _formatDateTime(String orderDate, String timeSlot) {
    try {
      final date = DateTime.parse(orderDate);
      final formattedDate =
          DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
      final convertedTime =
          TimezoneHelper.convertTime(timeSlot, currentTimezone);
      return '$formattedDate $convertedTime';
    } catch (e) {
      debugPrint('Error formatting date: $e');
      return '$orderDate $timeSlot';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFECE3),
      appBar: AppBar(
        title: const Text(
          "Riwayat Pesanan",
          style: TextStyle(
            fontFamily: "Poppins",
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4A70A9),
              ),
            )
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Belum ada riwayat pesanan",
                        style: TextStyle(
                          fontFamily: "Poppins",
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: const Color(0xFF4A70A9),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        return _buildOrderCard(orders[index]);
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final worker = order['worker'];
    final status = order['status'];
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);
    final formattedDateTime = _formatDateTime(
      order['order_date'],
      order['time_slot'],
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(orderId: order['id']),
          ),
        ).then((_) => _loadOrders());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Worker Photo
            Container(
              margin: const EdgeInsets.all(10),
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[300],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ImageHelper.buildNetworkImage(
                  photoUrl: worker?["photo"],
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Order Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10, right: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            worker?["name"] ?? "Unknown",
                            style: const TextStyle(
                              fontFamily: "Poppins",
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusLabel,
                            style: TextStyle(
                              fontFamily: "Poppins",
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      worker?["job_title"] ?? "",
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      formattedDateTime,
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCurrency(order["total_price"]),
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A70A9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
