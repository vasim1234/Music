import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const int _notificationId = 1;

  // Private callback variables
  static VoidCallback? _onPlayPause;
  static VoidCallback? _onNext;
  static VoidCallback? _onPrevious;
  static VoidCallback? _onClose;

  // Explicit Setters to fix the setter not found error
  static set onPlayPause(VoidCallback? callback) => _onPlayPause = callback;
  static set onNext(VoidCallback? callback) => _onNext = callback;
  static set onPrevious(VoidCallback? callback) => _onPrevious = callback;
  static set onClose(VoidCallback? callback) => _onClose = callback;

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    switch (response.actionId) {
      case 'play_pause':
        _onPlayPause?.call();
        break;
      case 'next':
        _onNext?.call();
        break;
      case 'previous':
        _onPrevious?.call();
        break;
      case 'close':
        _onClose?.call();
        break;
    }
  }

  static Future<void> showNowPlayingNotification({
    required String title,
    required String artist,
    required bool isPlaying,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'music_player_channel',
      'Music Player',
      channelDescription: 'Now playing music controls',
      importance: Importance.high,
      priority: Priority.high,
      ongoing: true,
      icon: const AndroidBitmap.fromString('@mipmap/ic_launcher'),
      actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'previous',
          '⏮️ Prev',
          icon: AndroidBitmap.fromString('ic_skip_previous'),
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'play_pause',
          isPlaying ? '⏸️ Pause' : '▶️ Play',
          icon: AndroidBitmap.fromString(isPlaying ? 'ic_pause' : 'ic_play_arrow'),
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'next',
          '⏭️ Next',
          icon: AndroidBitmap.fromString('ic_skip_next'),
          showsUserInterface: true,
        ),
        const AndroidNotificationAction(
          'close',
          '⏹️ Close',
          icon: AndroidBitmap.fromString('ic_close'),
          showsUserInterface: true,
        ),
      ],
    );

    final NotificationDetails details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _notificationId,
      isPlaying ? '▶️ Now Playing: $title' : '⏸️ Paused: $title',
      artist,
      details,
    );
  }

  static Future<void> cancelNotification() async {
    await _notifications.cancelAll();
  }
}
