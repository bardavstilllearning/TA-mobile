import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/api_service.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/session/session_manager.dart';
import 'start_page.dart';
import 'map_picker_page.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  double? latitude;
  double? longitude;
  bool isLoadingLocation = false;
  bool isSubmitting = false;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      CustomSnackbar.show(
        context,
        message: 'Error: $e!',
        backgroundColor: Colors.red,
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        CustomSnackbar.show(
          context,
          message: 'Layanan lokasi tidak aktif! Mohon aktifkan GPS!',
          backgroundColor: Colors.red,
        );
        setState(() => isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          CustomSnackbar.show(
            context,
            message: 'Izin lokasi ditolak!',
            backgroundColor: Colors.red,
          );
          setState(() => isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        CustomSnackbar.show(
          context,
          message:
              'Izin lokasi ditolak secara permanen! Mohon aktifkan di pengaturan aplikasi!',
          backgroundColor: Colors.red,
        );
        setState(() => isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          latitude = position.latitude;
          longitude = position.longitude;
        });

        await _getAddressFromCoordinates(position.latitude, position.longitude);

        CustomSnackbar.show(
          context,
          message: 'Lokasi berhasil didapatkan!',
          backgroundColor: Colors.green,
        );
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
      if (mounted) {
        setState(() => isLoadingLocation = false);
      }
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final address =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}';
        setState(() {
          addressController.text = address;
        });
      }
    } catch (e) {
      debugPrint('Error: $e!');
    }
  }

  Future<void> _openMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: latitude,
          initialLng: longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        latitude = result['latitude'];
        longitude = result['longitude'];
        addressController.text = result['address'];
      });

      CustomSnackbar.show(
        context,
        message: 'Lokasi berhasil dipilih dari peta!',
        backgroundColor: Colors.green,
      );
    }
  }

  Future<void> _submitProfile() async {
    if (phoneController.text.isEmpty || addressController.text.isEmpty) {
      return CustomSnackbar.show(
        context,
        message: 'Semua kolom wajib diisi!',
        backgroundColor: Colors.red,
      );
    }

    if (latitude == null || longitude == null) {
      return CustomSnackbar.show(
        context,
        message: 'Harap ambil lokasi Anda terlebih dahulu!',
        backgroundColor: Colors.red,
      );
    }

    setState(() => isSubmitting = true);

    try {
      final response = await ApiService.completeProfile(
        phone: phoneController.text,
        address: addressController.text,
        latitude: latitude!,
        longitude: longitude!,
      );

      if (response['success'] == true) {
        if (_selectedImage != null) {
          await ApiService.updateProfile(photo: _selectedImage);
        }

        await SessionManager.saveUser(response['user']);

        CustomSnackbar.show(context,
            message: 'Profil berhasil dilengkapi!',
            backgroundColor: Colors.green);

        await Future.delayed(const Duration(milliseconds: 600));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
        throw response['message'];
      }
    } catch (e) {
      CustomSnackbar.show(context,
          message: 'Error: $e!', backgroundColor: Colors.red);
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFECE3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Lengkapi Profil",
          style: TextStyle(
            color: Color(0xFF4A70A9),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selamat datang!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4A70A9),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Mohon lengkapi data Anda untuk melanjutkan.',
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 32),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : null,
                      child: _selectedImage == null
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4A70A9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt,
                            size: 18, color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: "Nomor WhatsApp",
                prefixIcon: const Icon(Icons.phone, color: Color(0xFF4A70A9)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Alamat Lengkap",
                prefixIcon: const Icon(Icons.home, color: Color(0xFF4A70A9)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isLoadingLocation ? null : _getCurrentLocation,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: isLoadingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            latitude != null
                                ? Icons.check_circle
                                : Icons.my_location,
                            color: const Color(0xFF4A70A9),
                          ),
                    label: const Text(
                      'Lokasi Saya',
                      style: TextStyle(
                        color: Color(0xFF4A70A9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openMapPicker,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.map, color: Color(0xFF4A70A9)),
                    label: const Text(
                      'Pilih di Peta',
                      style: TextStyle(
                        color: Color(0xFF4A70A9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (latitude != null && longitude != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lokasi Terdeteksi',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                              Text(
                                'Koordinat berhasil didapatkan',
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
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F7F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Latitude:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                latitude!.toStringAsFixed(6),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                'Longitude:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                longitude!.toStringAsFixed(6),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A70A9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      )
                    : const Text(
                        "Simpan & Lanjutkan",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 16,
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
