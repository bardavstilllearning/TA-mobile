import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../../../services/api_service.dart';
import '../../../widgets/custom_snackbar.dart';
import '../../../utils/helpers/timezone_helper.dart';
import '../../../utils/user_preferences.dart';
import '../before_page.dart';
import '../after_page.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../services/notification_service.dart';

class OrderDetailPage extends StatefulWidget {
  final int orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? order;
  bool isLoading = true;
  String currentTimezone = 'Asia/Jakarta';

  @override
  void initState() {
    super.initState();
    _loadTimezone();
    _loadOrderDetail();
  }

  Future<void> _loadTimezone() async {
    final tz = await UserPreferences.getTimezone();
    setState(() => currentTimezone = tz);
  }

  Future<void> _loadOrderDetail() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.getUserOrders();
      if (response['success'] == true) {
        final orders = List<Map<String, dynamic>>.from(response['orders']);
        final foundOrder = orders.firstWhere(
          (o) => o['id'] == widget.orderId,
          orElse: () => {},
        );

        if (foundOrder.isNotEmpty) {
          setState(() => order = foundOrder);
        }
      }
    } catch (e) {
      debugPrint('Error loading order: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      final response = await ApiService.updateOrderStatus(
        orderId: widget.orderId,
        status: status,
      );

      if (response['success'] == true) {
        if (mounted) {
          CustomSnackbar.show(
            context,
            message: 'Status berhasil diperbarui!',
            backgroundColor: Colors.green,
          );
        }
        await _loadOrderDetail();
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Error: $e!',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  // ✅ UPDATED: Handle Photo Before with notification
  Future<void> _handlePhotoBefore() async {
    final photo = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FotoBeforePage()),
    );

    if (photo != null && photo is File) {
      // Show loading notification
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Mengunggah foto sebelum pekerjaan dimulai!',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        );
        NotificationService.showPhotoUploadSuccess('before');
      }
      await _loadOrderDetail();

      try {
        final response = await ApiService.uploadPhotoBefore(
          orderId: widget.orderId,
          photo: photo,
        );

        if (response['success'] == true) {
          if (mounted) {
            // ✅ Show success notification
            CustomSnackbar.show(
              context,
              message: 'Foto sebelum pekerjaan dimulai berhasil diunggah!',
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            );
          }
          await _loadOrderDetail();
        } else {
          throw response['message'] ?? 'Gagal mengunggah foto!';
        }
      } catch (e) {
        if (mounted) {
          CustomSnackbar.show(
            context,
            message: 'Error: $e!',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  // ✅ UPDATED: Handle Photo After with notification
  Future<void> _handlePhotoAfter() async {
    final photo = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FotoAfterPage()),
    );

    if (photo != null && photo is File) {
      // Show loading notification
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Mengunggah foto setelah pekerjaan selesai!',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        );
        NotificationService.showPhotoUploadSuccess('after');
      }
      await _loadOrderDetail();
      try {
        final response = await ApiService.uploadPhotoAfter(
          orderId: widget.orderId,
          photo: photo,
        );

        if (response['success'] == true) {
          if (mounted) {
            CustomSnackbar.show(
              context,
              message: 'Foto setelah pekerjaan dilakukan berhasil diunggah!',
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            );
          }
          await _loadOrderDetail();
        } else {
          throw response['message'] ?? 'Gagal mengunggah foto!';
        }
      } catch (e) {
        if (mounted) {
          CustomSnackbar.show(
            context,
            message: 'Error: $e!',
            backgroundColor: Colors.red,
          );
        }
      }
    }
  }

  // ✅ UPDATED: Rating popup with notification
  void _showRatingPopup(BuildContext context) {
    double rating = 0;
    final TextEditingController ulasanController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Beri Rating & Ulasan",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 16),
              RatingBar.builder(
                initialRating: 0,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 34,
                unratedColor: Colors.grey[300],
                itemBuilder: (context, _) =>
                    const Icon(Icons.star_rounded, color: Colors.amber),
                onRatingUpdate: (value) {
                  rating = value;
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ulasanController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Tulis ulasan kamu di sini...",
                  hintStyle: const TextStyle(fontFamily: "Poppins"),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A70A9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    if (rating > 0) {
                      Navigator.pop(context);

                      if (mounted) {
                        CustomSnackbar.show(
                          context,
                          message: 'Mengirim Penilaian!',
                          backgroundColor: Colors.orange,
                          duration: const Duration(seconds: 2),
                        );
                      }

                      try {
                        final response = await ApiService.submitReview(
                          orderId: widget.orderId,
                          rating: rating,
                          review: ulasanController.text.isEmpty
                              ? null
                              : ulasanController.text,
                        );

                        if (response['success'] == true) {
                          if (mounted) {
                            // ✅ Show success notification with rating
                            CustomSnackbar.show(
                              context,
                              message:
                                  "✓ Terima kasih atas ulasannya! (${rating.toStringAsFixed(1)}⭐)",
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 3),
                            );
                            NotificationService.showRatingSuccess(rating);
                          }
                          await _loadOrderDetail();
                        } else {
                          throw response['message'] ?? 'Gagal submit review';
                        }
                      } catch (e) {
                        if (mounted) {
                          CustomSnackbar.show(
                            context,
                            message: 'Error $e!',
                            backgroundColor: Colors.red,
                          );
                        }
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Mohon isi rating.")),
                      );
                    }
                  },
                  child: const Text(
                    "Kirim",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEFECE3),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A70A9)),
        ),
      );
    }

    if (order == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFEFECE3),
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.white,
        ),
        body: const Center(child: Text('Order tidak ditemukan')),
      );
    }

    final worker = order!['worker'];
    final status = order!['status'];
    final orderDate = order!['order_date'];
    final timeSlot = order!['time_slot'];

    final convertedTime = TimezoneHelper.convertTime(timeSlot, currentTimezone);

    String formattedDate = orderDate;
    try {
      final date = DateTime.parse(orderDate);
      formattedDate = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      debugPrint('Error parsing date: $e');
    }

    String buttonLabel = '';
    VoidCallback? onButtonPressed;

    if (status == 'pending' || status == 'accepted') {
      buttonLabel = "Mulai Bekerja (Upload Foto Before)";
      onButtonPressed = _handlePhotoBefore;
    } else if (status == 'in_progress' && order!['photo_after'] == null) {
      buttonLabel = "Pekerjaan Selesai (Upload Foto After)";
      onButtonPressed = _handlePhotoAfter;
    } else if (status == 'completed' && order!['user_rating'] == null) {
      buttonLabel = "Beri Rating & Ulasan";
      onButtonPressed = () => _showRatingPopup(context);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFECE3),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            expandedHeight: 250,
            leading: Container(
              margin: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF4A70A9),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  "Detail Pesanan",
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: "Poppins",
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              background: worker != null && worker['photo'] != null
                  ? ClipRRect(
                      child: Image.network(
                        'http://192.168.18.37:8000/storage/${worker["photo"]}',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 60),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.person, size: 60),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              worker?["name"] ?? "Unknown",
                              style: const TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              worker?["job_title"] ?? "",
                              style: const TextStyle(
                                fontFamily: "Poppins",
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusLabel(status),
                          style: TextStyle(
                            fontFamily: "Poppins",
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF4A70A9),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                convertedTime,
                                style: const TextStyle(
                                  fontFamily: "Poppins",
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
                  const SizedBox(height: 16),
                  const Divider(thickness: 0.8),
                  const SizedBox(height: 16),
                  const Text(
                    "Progress Pekerjaan",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildProgressTimeline(status),
                  const SizedBox(height: 24),
                  if (order!['photo_before'] != null ||
                      order!['photo_after'] != null) ...[
                    const Text(
                      "Foto Bukti Pekerjaan",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (order!['photo_before'] != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Before',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A70A9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    'http://192.168.18.37:8000/storage/${order!["photo_before"]}',
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 40),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (order!['photo_before'] != null &&
                            order!['photo_after'] != null)
                          const SizedBox(width: 10),
                        if (order!['photo_after'] != null)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'After',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A70A9),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    'http://192.168.18.37:8000/storage/${order!["photo_after"]}',
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image, size: 40),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (order!['user_rating'] != null) ...[
                    const Divider(thickness: 0.8),
                    const SizedBox(height: 16),
                    const Text(
                      "Ulasan Anda",
                      style: TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${order!['user_rating']} / 5.0',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          if (order!['user_review'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              order!['user_review'],
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: buttonLabel.isNotEmpty
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0, -2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A70A9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: onButtonPressed,
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(
                        fontFamily: "Poppins",
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Diterima';
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

  Widget _buildProgressTimeline(String currentStatus) {
    final steps = [
      {'label': 'Pemesanan Diterima', 'status': 'accepted'},
      {'label': 'Mulai Bekerja', 'status': 'in_progress'},
      {'label': 'Pekerjaan Selesai', 'status': 'completed'},
    ];

    final statusOrder = ['pending', 'accepted', 'in_progress', 'completed'];
    final currentIndex = statusOrder.indexOf(currentStatus);

    return Column(
      children: List.generate(steps.length, (i) {
        final stepStatus = steps[i]['status'] as String;
        final stepIndex = statusOrder.indexOf(stepStatus);
        final isDone = stepIndex <= currentIndex;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone ? const Color(0xFF4A70A9) : Colors.grey[400],
                    border: Border.all(
                      color:
                          isDone ? const Color(0xFF4A70A9) : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        )
                      : null,
                ),
                if (i < steps.length - 1)
                  Container(
                    width: 2,
                    height: 40,
                    color: isDone ? const Color(0xFF4A70A9) : Colors.grey[300],
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2.0),
                child: Text(
                  steps[i]['label'] as String,
                  style: TextStyle(
                    fontFamily: "Poppins",
                    fontSize: 13,
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                    color: isDone ? Colors.black87 : Colors.black45,
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
