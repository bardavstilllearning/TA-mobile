import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ---------------------------------------------------------
  // INITIALIZE
  // ---------------------------------------------------------
  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint("Notification tapped: ${details.payload}");
      },
    );

    // ✅ FIXED: Request permissions for Android 13+ (API 33+)
    await _requestPermissions();
  }

  // ---------------------------------------------------------
  // REQUEST PERMISSIONS (ANDROID 13+)
  // ---------------------------------------------------------
  static Future<void> _requestPermissions() async {
    // ✅ FIXED: Use correct method for v17
    final androidPlatform =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlatform != null) {
      // ✅ For Android 13+ (API 33+), request notification permission
      final bool? granted =
          await androidPlatform.requestNotificationsPermission();
      debugPrint("Notification permission granted: $granted");
    }
  }

  // ---------------------------------------------------------
  // SHOW NOTIFICATION
  // ---------------------------------------------------------
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.info,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'kerahbiru_channel',
      'KerahBiru Notifications',
      channelDescription: 'Notifikasi untuk aplikasi KerahBiru',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // Unique ID
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // ---------------------------------------------------------
  // PREDEFINED TEMPLATES
  // ---------------------------------------------------------
  static Future<void> showPhotoUploadSuccess(String photoType) async {
    await showNotification(
      title: "Upload Berhasil",
      body: "Foto $photoType berhasil diupload!",
      type: NotificationType.success,
    );
  }

  static Future<void> showRatingSuccess(double rating) async {
    await showNotification(
      title: "Terima Kasih!",
      body: "Rating ${rating.toStringAsFixed(1)}⭐ berhasil dikirim.",
      type: NotificationType.success,
    );
  }

  static Future<void> showOrderCreated() async {
    await showNotification(
      title: "Pesanan Dibuat",
      body: "Pesanan Anda berhasil dibuat dan menunggu konfirmasi.",
      type: NotificationType.info,
    );
  }

  static Future<void> showError(String message) async {
    await showNotification(
      title: "Error",
      body: message,
      type: NotificationType.error,
    );
  }
}

enum NotificationType {
  info,
  success,
  error,
  warning,
}
