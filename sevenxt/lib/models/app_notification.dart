enum NotificationAudience {
  all,
  b2b,
  b2c,
}

class AppNotification {
  final String title;
  final String message;
  final String time;
  final NotificationAudience audience;

  AppNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.audience,
  });
}
