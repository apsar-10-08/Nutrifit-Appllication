// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'notification_service_interface.dart';

class AppNotificationServiceImpl implements AppNotificationService {
  @override
  Future<void> init() async {
    if (html.Notification.permission != 'granted') {
      await html.Notification.requestPermission();
    }
  }

  @override
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    // Web doesn't support background scheduling easily without service worker
  }

  @override
  Future<void> cancelNotification(int id) async {}
}

AppNotificationService getService() => AppNotificationServiceImpl();
