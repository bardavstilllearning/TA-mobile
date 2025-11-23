import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../services/api_service.dart';
import '../widgets/custom_snackbar.dart';
import 'complete_profil_page.dart';

class ShakeVerificationPage extends StatefulWidget {
  ShakeVerificationPage({super.key});

  @override
  State<ShakeVerificationPage> createState() => _ShakeVerificationPageState();
}

class _ShakeVerificationPageState extends State<ShakeVerificationPage>
    with SingleTickerProviderStateMixin {
  int shakeCount = 0;
  final int requiredShakes = 100;

  bool isShaking = false;
  bool isVerifying = false;

  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  AccelerometerEvent? _lastEvent;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _accelerometerSubscription?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startShakeDetection() {
    if (isShaking || isVerifying) return;

    setState(() {
      isShaking = true;
      shakeCount = 0;
    });

    _pulseController.repeat(reverse: true);

    const double shakeThreshold = 2.5;

    _lastEvent = null;
    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      if (!mounted) return;

      if (_lastEvent != null) {
        final dx = (event.x - _lastEvent!.x);
        final dy = (event.y - _lastEvent!.y);
        final dz = (event.z - _lastEvent!.z);

        final delta = sqrt(dx * dx + dy * dy + dz * dz);

        if (delta > shakeThreshold) {
          setState(() {
            shakeCount += 1;
            if (shakeCount >= requiredShakes) {
              _stopAndVerify();
            }
          });
        }
      }

      _lastEvent = event;
    });
  }

  Future<void> _stopAndVerify() async {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _pulseController.stop();
    _lastEvent = null;

    setState(() {
      isShaking = false;
      isVerifying = true;
    });

    try {
      final response = await ApiService.verifyShakeCaptcha();

      if (response['success'] == true && mounted) {
        CustomSnackbar.show(
          context,
          message: 'Verifikasi akun berhasil!',
          backgroundColor: Colors.green,
        );

        await Future.delayed(const Duration(milliseconds: 700));

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const CompleteProfilePage()),
        );
      } else {
        final msg = (response['message'] != null)
            ? response['message']
            : 'Verifikasi gagal';
        throw msg;
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackbar.show(
        context,
        message: 'Error: $e!',
        backgroundColor: Colors.red,
      );

      setState(() {
        isVerifying = false;
        shakeCount = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (shakeCount / requiredShakes).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFEFECE3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4A70A9).withOpacity(0.16),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.security_rounded,
                  size: 56,
                  color: Color(0xFF4A70A9),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Verifikasi Keamanan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A70A9),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Goyang HP kamu untuk membuktikan\nbahwa kamu adalah manusia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 40),

              Center(
                child: SizedBox(
                  width: 230,
                  height: 320, // sedikit lebih tinggi karena ada tombol
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // --- PROGRESS RING ---
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey.shade300,
                          valueColor:
                              const AlwaysStoppedAnimation(Color(0xFF4A70A9)),
                        ),
                      ),

                      // --- ANGKA SHAKE ---
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$shakeCount',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4A70A9),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '/ $requiredShakes',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),

                      // --- SHAKE BUTTON (DI ATAS PROGRESS) ---
                      if (!isShaking && !isVerifying)
                        Positioned(
                          bottom: 0,
                          child: AnimatedBuilder(
                            animation: _pulseAnim,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnim.value,
                                child: GestureDetector(
                                  onTap: _startShakeDetection,
                                  child: Container(
                                    width: 140,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4A70A9),
                                          Color(0xFF8FABD4),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF4A70A9)
                                              .withOpacity(0.35),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.touch_app_rounded,
                                        size: 56,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                      // --- LOADING STATE (SAAT VERIFY) ---
                      if (isVerifying)
                        const Positioned(
                          bottom: 10,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Status card
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isVerifying)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4A70A9),
                        ),
                      ),
                    if (isVerifying) const SizedBox(width: 12),
                    Text(
                      isVerifying
                          ? 'Memverifikasi...'
                          : isShaking
                              ? 'Terus goyang!'
                              : 'Ketuk untuk mulai',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4A70A9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              if (!isShaking && !isVerifying)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A70A9).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFF4A70A9)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Tips: Goyang HP dengan kuat & cepat. Pastikan device berada di tangan, bukan di meja.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 30),

              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'Progress akan otomatis tersimpan selama verifikasi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
