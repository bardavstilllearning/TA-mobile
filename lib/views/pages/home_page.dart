import 'package:flutter/material.dart';
import '../../widgets/custom_snackbar.dart';
import '../../services/api_service.dart';
import '../../utils/database/favorite_database.dart';
import '../../utils/helpers/currency_helper.dart';
import '../../utils/helpers/image_helper.dart';
import '../../utils/user_preferences.dart';
import 'detail/worker_detail_page.dart';

class BerandaPage extends StatefulWidget {
  const BerandaPage({super.key});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";
  String selectedFilter = "Semua";
  String currentCurrency = 'IDR';
  bool isLoading = false;
  bool isLoadingProfile = true;
  List<Map<String, dynamic>> workers = [];
  String userName = "";
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadUserId(),
      _loadCurrency(),
      _loadProfile(),
      _loadWorkers(),
    ]);
  }

  Future<void> _loadUserId() async {
    final userId = await UserPreferences.getUserId();
    setState(() => currentUserId = userId);
  }

  Future<void> _loadCurrency() async {
    final currency = await UserPreferences.getCurrency();
    if (mounted) {
      setState(() => currentCurrency = currency);
    }
  }

  Future<void> _loadProfile() async {
    setState(() => isLoadingProfile = true);

    try {
      final response = await ApiService.getProfile();
      if (response['success'] == true && mounted) {
        setState(() {
          userName = response['user']['name'] ?? 'User';
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
    } finally {
      if (mounted) {
        setState(() => isLoadingProfile = false);
      }
    }
  }

  Future<void> _loadWorkers() async {
    setState(() => isLoading = true);

    try {
      String? sortBy;
      String? gender;

      if (selectedFilter == "Terdekat" ||
          selectedFilter == "Termurah" ||
          selectedFilter == "Terpercaya") {
        sortBy = selectedFilter;
      } else if (selectedFilter == "Perempuan" ||
          selectedFilter == "Laki-Laki") {
        gender = selectedFilter;
      }

      final response = await ApiService.getWorkers(
        search: searchQuery.isEmpty ? null : searchQuery,
        gender: gender,
        sortBy: sortBy,
      );

      if (response['success'] == true && mounted) {
        setState(() {
          workers = List<Map<String, dynamic>>.from(
              response['workers'] ?? []); // ✅ Handle null
        });
      } else {
        _showError(response['message'] ?? 'Gagal memuat data');
      }
    } catch (e) {
      debugPrint('❌ Error loading workers: $e');
      _showError('Terjadi kesalahan saat memuat data');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _onSearchChanged(String value) async {
    setState(() => searchQuery = value);
    await Future.delayed(const Duration(milliseconds: 500));
    if (searchQuery == value) {
      _loadWorkers();
    }
  }

  Future<void> _changeFilter(String filter) async {
    if (selectedFilter == filter) return;

    setState(() {
      selectedFilter = filter;
      isLoading = true;
    });

    await _loadWorkers();
  }

  Future<void> _toggleFavorite(int index) async {
    if (currentUserId == null) {
      _showError('User ID tidak ditemukan');
      return;
    }

    final worker = workers[index];
    final workerId = worker['id'];
    final workerName = worker['name'] ?? 'Pekerja'; // ✅ Get worker name

    try {
      final isFav = await FavoriteDatabase.isFavorite(workerId, currentUserId!);

      if (isFav) {
        await FavoriteDatabase.removeFavorite(workerId, currentUserId!);
        _showSuccess("$workerName dihapus dari favorit!",
            isError: true); // ✅ Dengan nama
      } else {
        await FavoriteDatabase.addFavorite(worker, currentUserId!);
        _showSuccess('$workerName ditambahkan ke favorit!'); // ✅ Dengan nama
      }

      setState(() {}); // Trigger rebuild
    } catch (e) {
      debugPrint('❌ Error toggling favorite: $e');
      _showError('Gagal mengupdate favorit');
    }
  }

  String _formatCurrency(dynamic amount) {
    return CurrencyHelper.convertAndFormat(amount, currentCurrency);
  }

  double _parseRating(dynamic rating) {
    return rating != null ? double.tryParse(rating.toString()) ?? 0.0 : 0.0;
  }

  void _showSuccess(String message, {bool isError = false}) {
    if (mounted) {
      CustomSnackbar.show(
        context,
        message: message,
        backgroundColor: isError ? Colors.red : Colors.green,
      );
    }
  }

  void _showError(String message) {
    if (mounted) {
      CustomSnackbar.show(
        context,
        message: message,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        title: _buildSearchBar(),
        automaticallyImplyLeading: false,
      ),
      backgroundColor: const Color(0xFFEFECE3),
      body: SafeArea(
        child: Column(
          children: [
            _buildGreeting(),
            _buildFilterChips(),
            const SizedBox(height: 10),
            Expanded(child: _buildWorkerGrid()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: "Cari pekerja...",
        hintStyle: const TextStyle(fontFamily: "Poppins", fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Color(0xFF4A70A9)),
        filled: true,
        fillColor: const Color(0xFFF7F7F7),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: isLoadingProfile
            ? const Row(
                children: [
                  Text(
                    "Selamat Datang, ",
                    style: TextStyle(
                      fontFamily: "Poppins",
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              )
            : Text(
                "Selamat Datang, $userName!",
                style: const TextStyle(
                  fontFamily: "Poppins",
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      ("Semua", Icons.grid_view_rounded),
      ("Perempuan", Icons.woman_rounded),
      ("Laki-Laki", Icons.man_rounded),
      ("Termurah", Icons.attach_money_rounded),
      ("Terdekat", Icons.location_on_rounded),
      ("Terpercaya", Icons.star_rounded),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final (label, icon) = filters[index];
          return _buildFilterChip(label, icon);
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final bool isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () => _changeFilter(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A70A9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4A70A9)
                : Colors.grey.withOpacity(0.3),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF4A70A9).withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : const Color(0xFF4A70A9),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ FIX: GridView dengan proper empty check
  Widget _buildWorkerGrid() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF4A70A9),
        ),
      );
    }

    // ✅ CRITICAL: Check isEmpty BEFORE building GridView
    if (workers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isNotEmpty
                  ? 'Tidak ada pekerja ditemukan\nuntuk "$searchQuery"'
                  : 'Tidak ada pekerja tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadWorkers,
      color: const Color(0xFF4A70A9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: workers.length, // ✅ Safe to use now
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisExtent: 260,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            return _buildWorkerCard(workers[index], index);
          },
        ),
      ),
    );
  }

  Widget _buildWorkerCard(Map<String, dynamic> worker, int index) {
    final formattedHarga = _formatCurrency(worker["price_per_hour"]);
    final rating = _parseRating(worker["rating"]);
    final isTopRated = rating >= 4.8;

    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    return StatefulBuilder(
      builder: (context, setCardState) {
        return FutureBuilder<bool>(
          future: FavoriteDatabase.isFavorite(worker['id'], currentUserId!),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildWorkerCardLoading();
            }

            final isFavorite = snapshot.data ?? false;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkerDetailPage(worker: worker),
                  ),
                ).then((_) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _loadCurrency();
                      setState(() {});
                    }
                  });
                });
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
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      worker["name"] ?? "Unknown",
                                      style: const TextStyle(
                                        fontFamily: "Poppins",
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                  if (isTopRated) const SizedBox(width: 4),
                                  if (isTopRated)
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Color(0xFF4A70A9),
                                      size: 16,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                worker["job_title"] ?? "",
                                style: const TextStyle(
                                  fontFamily: "Poppins",
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star_rounded,
                                    color: Colors.amber,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    "${worker["rating"] ?? '0.0'}| ${worker["total_orders"] ?? 0}x",
                                    style: const TextStyle(
                                      fontFamily: "Poppins",
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.location_on,
                                    color: Color(0xFF8FABD4),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: Text(
                                      "${worker["distance"] ?? 0} km",
                                      style: const TextStyle(
                                        fontFamily: "Poppins",
                                        fontSize: 11,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
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
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () async {
                          if (currentUserId == null) return;

                          setCardState(() {});

                          try {
                            final currentFav =
                                await FavoriteDatabase.isFavorite(
                              worker['id'],
                              currentUserId!,
                            );

                            if (currentFav) {
                              await FavoriteDatabase.removeFavorite(
                                worker['id'],
                                currentUserId!,
                              );
                              if (mounted) {
                                CustomSnackbar.show(
                                  context,
                                  message:
                                      "${worker['name']} dihapus dari favorit!",
                                  backgroundColor: Colors.red,
                                );
                              }
                            } else {
                              await FavoriteDatabase.addFavorite(
                                worker,
                                currentUserId!,
                              );
                              if (mounted) {
                                CustomSnackbar.show(
                                  context,
                                  message:
                                      '${worker['name']} ditambahkan ke favorit!',
                                  backgroundColor: Colors.green,
                                );
                              }
                            }

                            setCardState(() {});
                          } catch (e) {
                            debugPrint('❌ Error toggling favorite: $e');
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
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
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite
                                ? Colors.red
                                : const Color(0xFF4A70A9),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWorkerCardLoading() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 60),
                Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF4A70A9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
