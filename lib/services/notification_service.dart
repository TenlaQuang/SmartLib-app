import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Khởi tạo Dịch vụ Thông báo
  Future<void> init() async {
    if (_isInitialized) return;

    // Cấu hình cho Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Cấu hình cho iOS
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    // Tiến hành khởi tạo
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Xử lý khi người dùng click vào thông báo (nếu cần)
        debugPrint("Click notification: ${response.payload}");
      },
    );

    _isInitialized = true;
    debugPrint("--- NotificationService Initialized Successful ---");
  }

  /// Gửi yêu cầu xin quyền thông báo của điện thoại (Android & iOS)
  Future<bool> requestPermissions() async {
    await init(); // Đảm bảo đã khởi tạo
    
    // Yêu cầu quyền trên iOS
    final bool? iosGranted = await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Yêu cầu quyền trên Android (cho Android 13+)
    final bool? androidGranted = await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    final isGranted = (iosGranted ?? false) || (androidGranted ?? false);
    debugPrint("--- Notification Permissions Granted: $isGranted ---");
    return isGranted;
  }

  /// Hiển thị thông báo dạng Tin nhắn bật lên (Popup/Banner) của Điện thoại
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await init(); // Đảm bảo đã khởi tạo

    // Chi tiết cấu hình cho Android (Hiển thị dạng Banner nổi bật)
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'smartlib_urgent_channel', // ID kênh
      'Thông báo SmartLib',      // Tên kênh
      channelDescription: 'Kênh thông báo tin tức và cảnh báo hết hạn sách',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
    );

    // Chi tiết cấu hình cho iOS
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // Tạo ID ngẫu nhiên cho thông báo
    final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    
    await _localNotificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
    debugPrint("--- Showed Local Notification: '$title' ---");
  }
}
