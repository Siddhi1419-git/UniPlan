import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  // Initialize notification service
  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted notification permission');
    } else {
      debugPrint('User declined notification permission');
      return;
    }

    // Initialize local notifications for foreground
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();

    // Get FCM token
    _fcmToken = await _messaging.getToken();
    debugPrint('FCM Token: $_fcmToken');

    // Save token to Firebase for current user
    await _saveTokenToFirebase(_fcmToken);

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      _saveTokenToFirebase(newToken);
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background messages (when app is terminated)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'uniplan_notifications',
      'UniPlan Notifications',
      description: 'Notifications for timetable updates and announcements',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> _saveTokenToFirebase(String? token) async {
    if (token == null) return;
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _database.ref('users/${user.uid}/fcmToken').set(token);
      debugPrint('FCM token saved to Firebase');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle navigation based on payload if needed
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.notification?.title}');

    // Show local notification when app is in foreground
    await _showLocalNotification(
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
    );
  }

  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('Background message opened app: ${message.notification?.title}');
    // Handle navigation if needed
  }

  Future<void> _showLocalNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'uniplan_notifications',
      'UniPlan Notifications',
      channelDescription: 'Notifications for timetable updates and announcements',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      details,
    );
  }

  // Send notification to specific users (Admin function)
  Future<void> sendNotificationToUsers({
    required String title,
    required String body,
    String? semesterId,
    String? divisionId,
    String? userId,
  }) async {
    try {
      DatabaseReference tokensRef = _database.ref('users');

      // Save to /announcements so students see it in-app (works without FCM/Cloud Functions)
      await _database.ref('announcements').push().set({
        'title': title,
        'body': body,
        'semesterId': semesterId ?? '',
        'divisionId': divisionId ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (userId != null) {
        // Send to specific user
        final snapshot = await tokensRef.child('$userId/fcmToken').get();
        if (snapshot.exists) {
          final token = snapshot.value as String;
          await _sendToFCM(token, title, body);
        }
      } else {
        // Send to multiple users based on filters
        final snapshot = await tokensRef.get();
        if (snapshot.exists) {
          final users = snapshot.value as Map;
          for (var entry in users.entries) {
            final userData = entry.value as Map;
            final userToken = userData['fcmToken'] as String?;
            
            if (userToken == null) continue;

            // Apply filters
            bool shouldSend = true;
            if (semesterId != null && semesterId.isNotEmpty && userData['semesterId'] != semesterId) {
              shouldSend = false;
            }
            if (divisionId != null && divisionId.isNotEmpty && userData['divisionId'] != divisionId) {
              shouldSend = false;
            }

            if (shouldSend) {
              await _sendToFCM(userToken, title, body);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
      rethrow;
    }
  }

  Future<void> _sendToFCM(String token, String title, String body) async {
    // Note: In production, you should use Firebase Cloud Functions or your backend
    // to send FCM messages. This is a simplified version.
    // For now, we'll store the notification in Firebase and use Cloud Functions
    // or a backend service to actually send it.
    
    // Store notification in Firebase for Cloud Functions to process
    await _database.ref('notifications').push().set({
      'token': token,
      'title': title,
      'body': body,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

