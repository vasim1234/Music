import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static int _notificationId = 1;
  
  static VoidCallback? onPlayPause;
  static VoidCallback? onNext;
  static VoidCallback? onPrevious;
  static VoidCallback? onClose;

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(settings, onDidReceiveNotificationResponse: _handleNotificationResponse);
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    switch (response.payload) {
      case 'play_pause':
        onPlayPause?.call();
        break;
      case 'next':
        onNext?.call();
        break;
      case 'previous':
        onPrevious?.call();
        break;
      case 'close':
        onClose?.call();
        break;
    }
  }

  static Future<void> showNowPlayingNotification({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    // ✅ CORRECT WAY - WITHOUT AndroidBitmap
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'music_player_channel',
      'Music Player',
      channelDescription: 'Now playing music controls',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      icon: '@mipmap/ic_launcher',
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'previous',
          '⏮️ Prev',
          icon: 'ic_skip_previous',  // ✅ Direct String
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'play_pause',
          isPlaying ? '⏸️ Pause' : '▶️ Play',
          icon: isPlaying ? 'ic_pause' : 'ic_play_arrow',  // ✅ Direct String
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'next',
          '⏭️ Next',
          icon: 'ic_skip_next',  // ✅ Direct String
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'close',
          '⏹️ Close',
          icon: 'ic_close',  // ✅ Direct String
          showsUserInterface: true,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _notificationId++,
      isPlaying ? '▶️ Now Playing: $title' : '⏸️ Paused: $title',
      artist,
      details,
      payload: 'now_playing',
    );
  }

  static Future<void> updatePlayPauseButton(bool isPlaying, String title, String artist) async {
    await showNowPlayingNotification(
      title: title,
      artist: artist,
      isPlaying: isPlaying,
    );
  }

  static Future<void> cancelNotification() async {
    await _notifications.cancelAll();
  }
}
