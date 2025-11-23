import 'dart:async';
import 'package:flutter/material.dart';
import 'session_manager.dart';
import '../../views/auth_page.dart';
import '../../widgets/custom_snackbar.dart';

class SessionChecker {
  static Timer? _timer;

  // Cek session setiap 10 detik
  static void startChecking(BuildContext context) {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final isValid = await SessionManager.isSessionValid();

      if (!isValid && context.mounted) {
        timer.cancel();
        await SessionManager.clearSession();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthPage()),
          (route) => false,
        );

        CustomSnackbar.show(
          context,
          message: "Sesi telah habis, silakan masuk kembali!",
          backgroundColor: Colors.red,
        );
      }
    });
  }

  static void stopChecking() {
    _timer?.cancel();
    _timer = null;
  }
}
