import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background handler. Must be a top-level (or static) function so
/// it can run in its own isolate when the app is terminated/in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase must be initialized in this isolate too.
  await Firebase.initializeApp();
  await PushService.instance._showFromRemote(message);
}

/// Wraps Firebase Cloud Messaging + flutter_local_notifications so that
/// messages delivered by Stream show up in the Android notification bar,
/// including when the app is closed.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'stream_chat_messages',
    'Chat Messages',
    description: 'Notifications for new chat messages and mentions',
    importance: Importance.high,
  );

  bool _initialized = false;

  /// Call once at startup (after Firebase.initializeApp).
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Local notifications setup (Android).
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(initSettings);

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Ask for notification permission (Android 13+ / iOS).
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages: show them ourselves (FCM won't auto-display these).
    FirebaseMessaging.onMessage.listen(_showFromRemote);

    // Background handler is registered in main().
  }

  /// The device's FCM token, used to register the device with Stream.
  Future<String?> getToken() => FirebaseMessaging.instance.getToken();

  /// Forwards token refreshes so the caller can re-register with Stream.
  Stream<String> get onTokenRefresh =>
      FirebaseMessaging.instance.onTokenRefresh;

  Future<void> _showFromRemote(RemoteMessage message) async {
    // Stream sends data-only and/or notification payloads. Build a title/body
    // from whichever is present.
    String title = message.notification?.title ?? '';
    String body = message.notification?.body ?? '';

    if (title.isEmpty || body.isEmpty) {
      final data = message.data;
      // Stream's data payload commonly includes sender + message text.
      final sender = data['sender_name'] ??
          data['user'] ??
          data['sender'] ??
          'New message';
      String text = data['message'] ?? data['body'] ?? data['text'] ?? '';
      if (text.isEmpty && data['stream'] != null) {
        // Stream sometimes nests its payload under a "stream" JSON string.
        try {
          final nested = jsonDecode(data['stream'] as String);
          text = (nested['message'] is Map)
              ? (nested['message']['text']?.toString() ?? '')
              : '';
        } catch (_) {}
      }
      if (title.isEmpty) title = sender.toString();
      if (body.isEmpty) body = text.isEmpty ? 'You have a new message' : text;
    }

    await _local.show(
      message.hashCode,
      title.isEmpty ? 'New message' : title,
      body.isEmpty ? 'You have a new message' : body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'stream_chat_messages',
          'Chat Messages',
          channelDescription:
              'Notifications for new chat messages and mentions',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  void logError(Object e) => debugPrint('PushService error: $e');
}
