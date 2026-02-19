import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  static const _channelId = 'coinhabit_reminders';
  static const _channelName = 'CoinHabit Reminders';
  static const _dailyReminderNotificationId = 1001;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  StreamSubscription<RemoteMessage>? _onMessageSubscription;
  StreamSubscription<String>? _onTokenRefreshSubscription;
  String? _fcmToken;
  bool _initialized = false;
  bool _timezoneInitialized = false;

  String? get fcmToken => _fcmToken;

  Future<void> init(
      {Future<void> Function(String token)? onTokenChanged}) async {
    if (_initialized) {
      return;
    }

    _initializeTimezone();
    await _initializeLocalNotifications();
    await _initializeFirebaseMessaging(onTokenChanged: onTokenChanged);
    _initialized = true;
  }

  void _initializeTimezone() {
    if (_timezoneInitialized) {
      return;
    }

    tz.initializeTimeZones();
    _timezoneInitialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(initializationSettings);

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily reminders and reward notifications',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _initializeFirebaseMessaging({
    Future<void> Function(String token)? onTokenChanged,
  }) async {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      return;
    }

    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (_) {}

    try {
      _fcmToken = await messaging.getToken();
      if (_fcmToken != null && onTokenChanged != null) {
        await onTokenChanged(_fcmToken!);
      }
    } catch (_) {}

    _onTokenRefreshSubscription ??=
        messaging.onTokenRefresh.listen((token) async {
      _fcmToken = token;
      if (onTokenChanged != null) {
        await onTokenChanged(token);
      }
    });

    _onMessageSubscription ??= FirebaseMessaging.onMessage.listen(
      (message) async {
        final notification = message.notification;
        if (notification == null) {
          return;
        }

        await showLocalNotification(
          title: notification.title ?? 'CoinHabit',
          body: notification.body ?? 'You have a new update',
        );
      },
    );
  }

  Future<void> showLocalNotification({
    required String title,
    required String body,
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = 'CoinHabit Reminder',
    String body = 'Don\'t forget to check in and add to your goals today!',
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _localNotifications.zonedSchedule(
      _dailyReminderNotificationId,
      title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleDailyReminderFromString(String hhmm) async {
    final parts = hhmm.split(':');
    if (parts.length < 2) {
      return;
    }

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return;
    }

    await scheduleDailyReminder(hour: hour, minute: minute);
  }

  Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(_dailyReminderNotificationId);
  }

  Future<void> dispose() async {
    await _onMessageSubscription?.cancel();
    await _onTokenRefreshSubscription?.cancel();
    _onMessageSubscription = null;
    _onTokenRefreshSubscription = null;
    _initialized = false;
  }
}
