// ⚙️ KONFIGURASI APLIKASI TERPUSAT
class AppConfig {
  // 🌐 API Configuration
  // ⚠️ GANTI IP INI SESUAI SERVER KAMU!
  static const String API_BASE_URL = "http://192.168.18.37:8000/api";

  // ⏰ Session Configuration
  // ✅ GANTI DURASI SESI DISINI (dalam menit)
  static const int SESSION_DURATION_MINUTES = 10;
  static int get sessionDurationSeconds => SESSION_DURATION_MINUTES * 60;

  // 🖼️ Storage URL untuk gambar
  static String get storageUrl => API_BASE_URL.replaceAll('/api', '/storage');

  // 🔐 Security
  static const bool USE_ENCRYPTION = true;

  // 🎨 App Info
  static const String APP_NAME = "KerahBiru";
  static const String APP_VERSION = "1.0.0";
  static const String APP_DESCRIPTION = "Platform Insan Karya Raga";
}
