import 'notification_service_interface.dart';
import 'notification_service_mobile.dart' if (dart.library.html) 'notification_service_web.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  
  late final AppNotificationService _impl;
  
  NotificationService._internal() {
    _impl = getService();
  }

  Future<void> init() => _impl.init();
  
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) => _impl.scheduleDailyNotification(
    id: id,
    title: title,
    body: body,
    hour: hour,
    minute: minute,
  );
  
  Future<void> cancelNotification(int id) => _impl.cancelNotification(id);
}
