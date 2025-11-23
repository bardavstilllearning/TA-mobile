import 'package:shared_preferences/shared_preferences.dart';
import '../../config/app_config.dart';

class SessionManager {
  // ⏰ Ambil durasi dari config
  static int get sessionDuration => AppConfig.sessionDurationSeconds;

  // Simpan waktu login
  static Future<void> saveLoginTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('login_time', DateTime.now().millisecondsSinceEpoch);
  }

  // Cek apakah sesi masih valid
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final loginTime = prefs.getInt('login_time');

    if (loginTime == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = (now - loginTime) ~/ 1000;

    print(
        '⏱️ Session: $elapsed / $sessionDuration detik (${AppConfig.SESSION_DURATION_MINUTES} menit)');

    return elapsed < sessionDuration;
  }

  // Clear session
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('login_time');
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    print('🗑️ Session cleared');
  }

  // Simpan data user
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', user['name'] ?? '');
    await prefs.setString('user_email', user['email'] ?? '');
    await prefs.setBool('is_profile_complete',
        user['phone'] != null && user['address'] != null);
  }

  // Cek apakah profile sudah lengkap
  static Future<bool> isProfileComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_profile_complete') ?? false;
  }
}
