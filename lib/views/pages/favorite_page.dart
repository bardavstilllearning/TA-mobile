import 'package:flutter/material.dart';
import '../../widgets/custom_snackbar.dart';
import '../../utils/database/favorite_database.dart';
import '../../utils/helpers/currency_helper.dart';
import '../../utils/helpers/image_helper.dart';
import '../../utils/user_preferences.dart';
import 'detail/worker_detail_page.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({super.key});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  List<Map<String, dynamic>> favoriteWorkers = [];
  bool isLoading = true;
  int? currentUserId;
  String currentCurrency = 'IDR';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final userId = await UserPreferences.getUserId();
    final currency = await UserPreferences.getCurrency();

    setState(() {
      currentUserId = userId;
      currentCurrency = currency;
    });

    await _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (currentUserId == null) {
      setState(() => isLoading = false);
      return;
    }

    setState(() => isLoading = true);

    try {
      final favorites = await FavoriteDatabase.getAllFavorites(currentUserId!);
      if (mounted) {
        setState(() {
          favoriteWorkers = favorites;
        });
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _removeFavorite(int workerId, String workerName) async {
    if (currentUserId == null) return;

    await FavoriteDatabase.removeFavorite(workerId, currentUserId!);

    if (mounted) {
      CustomSnackbar.show(
        context,
        message: "Dihapus dari favorit!",
        backgroundColor: Colors.red,
      );
    }

    _loadFavorites();
  }

  String _formatCurrency(dynamic amount) {
    return CurrencyHelper.convertAndFormat(amount, currentCurrency);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFECE3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Pekerja Favorit",
          style: TextStyle(
            color: Color(0xFF4A70A9),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favoriteWorkers.isEmpty
              ? const Center(
                  child: Text(
                    "Belum ada pekerja favorit",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: GridView.builder(
                      itemCount: favoriteWorkers.length,
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 260,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemBuilder: (context, index) {
                        return _buildWorkerCard(favoriteWorkers[index]);
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker) {
    final formattedHarga = _formatCurrency(worker["price"]);
    final rating = worker["rating"] != null
        ? double.tryParse(worker["rating"].toString()) ?? 0.0
        : 0.0;
    final isTopRated = rating >= 4.8;
    final workerData = {
      'id': worker['worker_id'],
      'name': worker['name'],
      'job_title': worker['job_title'],
      'rating': worker['rating'],
      'distance': worker['distance'],
      'price_per_hour': worker['price'],
      'gender': worker['gender'],
      'photo': worker['photo'],
      'total_orders': worker['total_orders'],
    };
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => WorkerDetailPage(worker: workerData)),
        ).then((_) => _loadFavorites());
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                  ),
                  child: ImageHelper.buildNetworkImage(
                    photoUrl: worker["photo"],
                    width: double.infinity,
                    height: 130,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              worker["name"],
                              style: const TextStyle(
                                fontFamily: "Poppins",
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isTopRated)
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF4A70A9),
                              size: 18,
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        worker["job_title"],
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            "${worker["rating"]} | ${worker["total_orders"]}x",
                            style: const TextStyle(
                                fontFamily: "Poppins", fontSize: 12),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.location_on,
                              color: Color(0xFF8FABD4), size: 16),
                          Text(
                            "${worker["distance"]} km",
                            style: const TextStyle(
                                fontFamily: "Poppins", fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "$formattedHarga/jam",
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A70A9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 10,
              right: 10,
              child: GestureDetector(
                onTap: () =>
                    _removeFavorite(worker["worker_id"], worker["name"]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.red,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
