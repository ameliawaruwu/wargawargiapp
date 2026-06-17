import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';

class NotificationHelper {
  static final NotificationHelper instance = NotificationHelper._init();
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationHelper._init();

  Future<void> initialize() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) async {
        final payload = details.payload;
        if (payload != null && payload.isNotEmpty) {
          try {
            await OpenFile.open(payload);
          } catch (e) {
            print("Error opening file from notification: $e");
          }
        }
      },
    );

    // Request permissions for Android 13+
    try {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (e) {
      print("Error requesting notification permission: $e");
    }
  }

  Future<void> showDownloadNotification(String title, String body, String filePath) async {
    const androidDetails = AndroidNotificationDetails(
      'pdf_downloads',
      'Unduhan PDF',
      channelDescription: 'Notifikasi ketika berkas PDF selesai diunduh',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      filePath.hashCode,
      title,
      body,
      notificationDetails,
      payload: filePath,
    );
  }
}
