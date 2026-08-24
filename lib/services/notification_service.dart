import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings);
  }

  static Future<void> showNowPlayingNotification({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'music_player_channel',
      'Music Player',
      channelDescription: 'Now playing music controls',
      importance: Importance.low,
      priority: Priority.high,
      ongoing: true,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      0,
      isPlaying ? '▶️ Playing: $title' : '⏸️ Paused: $title',
      artist,
      details,
    );
  }

  static Future<void> cancelNotification() async {
    await _notifications.cancel(0);
  }
}
