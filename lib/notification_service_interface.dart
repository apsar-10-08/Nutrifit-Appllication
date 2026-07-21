abstract class AppNotificationService {
  Future<void> init();
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  });
  Future<void> cancelNotification(int id);
}
