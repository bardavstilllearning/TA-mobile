import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import '../../../services/api_service.dart';
import '../../../widgets/custom_snackbar.dart';
import '../../../utils/helpers/encryption_helper.dart';
import '../../map_picker_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _image;
  final picker = ImagePicker();

  final TextEditingController nameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController phoneC = TextEditingController();
  final TextEditingController addressC = TextEditingController();

  bool isLoading = true;
  bool isSaving = false;
  bool isLoadingLocation = false;
  String? currentPhotoUrl;

  double? latitude;
  double? longitude;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => isLoading = true);

    try {
      final response = await ApiService.getProfile();
      if (response['success'] == true) {
        final user = response['user'];
        setState(() {
          nameC.text = user['name'] ?? '';
          emailC.text = user['email'] ?? '';
          phoneC.text = user['phone'] ?? '';
          addressC.text = user['address'] ?? '';
          currentPhotoUrl = user['photo'];
          latitude = user['latitude'] != null
              ? double.tryParse(user['latitude'].toString())
              : null;
          longitude = user['longitude'] != null
              ? double.tryParse(user['longitude'].toString())
              : null;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Layanan lokasi tidak aktif. Mohon aktifkan GPS.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Izin lokasi ditolak';
        }
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
          message: 'Lokasi berhasil didapatkan! ✓',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Error: $e',
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
          addressC.text = address;
        });
      }
    } catch (e) {
      debugPrint('❌ Reverse geocoding error: $e');
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
        addressC.text = result['address'];
      });

      CustomSnackbar.show(
        context,
        message: 'Lokasi berhasil dipilih dari peta! ✓',
        backgroundColor: Colors.green,
      );
    }
  }

  // ✅ NEW: Change Password Dialog
  void _showChangePasswordDialog() {
    final currentPasswordC = TextEditingController();
    final newPasswordC = TextEditingController();
    final confirmPasswordC = TextEditingController();
    bool showCurrentPass = false;
    bool showNewPass = false;
    bool showConfirmPass = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Ubah Password',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordC,
                  obscureText: !showCurrentPass,
                  decoration: InputDecoration(
                    labelText: 'Password Saat Ini',
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showCurrentPass
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showCurrentPass = !showCurrentPass;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordC,
                  obscureText: !showNewPass,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showNewPass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showNewPass = !showNewPass;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordC,
                  obscureText: !showConfirmPass,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    labelStyle: const TextStyle(fontFamily: 'Poppins'),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        showConfirmPass
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          showConfirmPass = !showConfirmPass;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batal',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A70A9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                if (currentPasswordC.text.isEmpty ||
                    newPasswordC.text.isEmpty ||
                    confirmPasswordC.text.isEmpty) {
                  CustomSnackbar.show(
                    context,
                    message: 'Semua field wajib diisi!',
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                if (newPasswordC.text != confirmPasswordC.text) {
                  CustomSnackbar.show(
                    context,
                    message: 'Password baru tidak cocok!',
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                if (newPasswordC.text.length < 6) {
                  CustomSnackbar.show(
                    context,
                    message: 'Password minimal 6 karakter!',
                    backgroundColor: Colors.red,
                  );
                  return;
                }

                try {
                  final response = await ApiService.updatePassword(
                    currentPassword:
                        EncryptionHelper.encryptPassword(currentPasswordC.text),
                    newPassword:
                        EncryptionHelper.encryptPassword(newPasswordC.text),
                  );

                  if (response['success'] == true) {
                    Navigator.pop(context);
                    CustomSnackbar.show(
                      context,
                      message: 'Password berhasil diubah! ✓',
                      backgroundColor: Colors.green,
                    );
                  } else {
                    throw response['message'] ?? 'Gagal mengubah password';
                  }
                } catch (e) {
                  CustomSnackbar.show(
                    context,
                    message: 'Error: $e',
                    backgroundColor: Colors.red,
                  );
                }
              },
              child: const Text(
                'Ubah',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (nameC.text.isEmpty || phoneC.text.isEmpty || addressC.text.isEmpty) {
      CustomSnackbar.show(
        context,
        message: 'Semua kolom wajib diisi!',
        backgroundColor: Colors.red,
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final response = await ApiService.updateProfile(
        name: nameC.text,
        phone: phoneC.text,
        address: addressC.text,
        photo: _image,
      );

      if (response['success'] == true) {
        if (mounted) {
          CustomSnackbar.show(
            context,
            message: 'Profile berhasil diupdate! ✓',
            backgroundColor: Colors.green,
          );

          await Future.delayed(const Duration(milliseconds: 500));
          Navigator.pop(context, true);
        }
      } else {
        throw response['message'] ?? 'Gagal update profile';
      }
    } catch (e) {
      if (mounted) {
        CustomSnackbar.show(
          context,
          message: 'Error: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFECE3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Edit Profil",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
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
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          const SizedBox(height: 10),

          // FOTO PROFILE
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 55,
                  backgroundImage: _image != null
                      ? FileImage(_image!)
                      : currentPhotoUrl != null
                          ? NetworkImage(
                              'http://192.168.18.37:8000/storage/$currentPhotoUrl')
                          : const AssetImage("assets/images/user.jpg")
                              as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFF4A70A9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          _buildField(label: "Nama", controller: nameC),
          _buildField(
            label: "Email",
            controller: emailC,
            enabled: false,
            keyboard: TextInputType.emailAddress,
          ),
          _buildField(
            label: "No. HP",
            controller: phoneC,
            keyboard: TextInputType.phone,
          ),
          _buildField(label: "Alamat", controller: addressC, maxLines: 2),

          const SizedBox(height: 16),

          // Location Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isLoadingLocation ? null : _getCurrentLocation,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: latitude != null
                          ? Colors.green
                          : const Color(0xFF4A70A9),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isLoadingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          latitude != null
                              ? Icons.check_circle
                              : Icons.my_location,
                          color: latitude != null
                              ? Colors.green
                              : const Color(0xFF4A70A9),
                        ),
                  label: Text(
                    'Lokasi Saya',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: latitude != null
                          ? Colors.green
                          : const Color(0xFF4A70A9),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
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
                    side: const BorderSide(color: Color(0xFF4A70A9)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(
                    Icons.map,
                    color: Color(0xFF4A70A9),
                  ),
                  label: const Text(
                    'Pilih di Peta',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF4A70A9),
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (latitude != null && longitude != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lokasi: ${latitude!.toStringAsFixed(6)}, ${longitude!.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 25),

          // ✅ NEW: Change Password Button
          OutlinedButton.icon(
            onPressed: _showChangePasswordDialog,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF4A70A9)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.lock_outline, color: Color(0xFF4A70A9)),
            label: const Text(
              'Ubah Password',
              style: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFF4A70A9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 25),
          _saveBtn(context),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            enabled: enabled,
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey[200],
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveBtn(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4A70A9),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: isSaving ? null : _saveProfile,
      child: isSaving
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Text(
              "Simpan",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
    );
  }
}
