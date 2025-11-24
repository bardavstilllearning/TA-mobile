import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const MapPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late MapController _mapController;
  late LatLng _selectedLocation;
  String _selectedAddress = 'Memuat alamat...';
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
      _getAddressFromCoordinates(
          _selectedLocation.latitude, _selectedLocation.longitude);
    } else {
      _selectedLocation = const LatLng(-7.797068, 110.370529);
      _getCurrentLocationForMap();
    }
  }

  Future<void> _getCurrentLocationForMap() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });

        _mapController.move(_selectedLocation, 15.0);

        await _getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
      }
    } catch (e) {
      debugPrint('Error: $e!');
    }
  }

  Future<void> _getAddressFromCoordinates(double lat, double lng) async {
    setState(() => _isLoadingAddress = true);

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks[0];
        final address =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea}';
        setState(() {
          _selectedAddress = address;
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = 'Gagal memuat alamat!';
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    _getAddressFromCoordinates(latLng.latitude, latLng.longitude);
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'latitude': _selectedLocation.latitude,
      'longitude': _selectedLocation.longitude,
      'address': _selectedAddress,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          'Pilih Lokasi',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF4A70A9)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15.0,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.kerahbiru.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_pin,
                      color: Color(0xFF4A70A9),
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Color(0xFF4A70A9), size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Alamat Terpilih',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      if (_isLoadingAddress) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedAddress,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: _isLoadingAddress ? null : _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A70A9),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Konfirmasi Lokasi',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
