import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:crush/core/services/supabase_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('[NotificationService] Handling background message: ${message.messageId}');
  } catch (e) {
    debugPrint('[NotificationService] Error in background message handler: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize Firebase Messaging and setup notification permissions
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;

      // Request permission on iOS
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('[NotificationService] Permission status: ${settings.authorizationStatus}');

      // Enable presentation in foreground for iOS
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // On iOS, wait for APNs token before retrieving FCM token
      if (Platform.isIOS) {
        final apnsToken = await messaging.getAPNSToken();
        debugPrint('[NotificationService] APNs Token received: ${apnsToken != null}');
      }

      // Retrieve FCM device token
      try {
        _fcmToken = await messaging.getToken();
        debugPrint('[NotificationService] FCM Token: $_fcmToken');
      } catch (e) {
        debugPrint('[NotificationService] Token read note: $e');
      }

      // Listen for token refreshes
      messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        debugPrint('[NotificationService] FCM Token refreshed: $newToken');
        _syncCurrentProfileToken(newToken);
      });

      // Setup foreground handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Foreground message received: ${message.notification?.title}');
      });

      // Setup background/opened app handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[NotificationService] Notification opened app: ${message.data}');
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Firebase Messaging init error: $e');
    }
  }

  /// Sync device FCM token to Supabase profile
  Future<void> syncUserFcmToken(String userId) async {
    if (userId.isEmpty) return;

    try {
      _fcmToken ??= await FirebaseMessaging.instance.getToken();
      if (_fcmToken != null && _supabaseService.client != null) {
        await _supabaseService.client!
            .from('profiles')
            .update({'fcm_token': _fcmToken})
            .eq('id', userId);
        debugPrint('[NotificationService] Synced FCM token to profile $userId');
      }
    } catch (e) {
      // Non-fatal if column doesn't exist yet in Supabase
      debugPrint('[NotificationService] Error syncing FCM token: $e');
    }
  }

  Future<void> _syncCurrentProfileToken(String token) async {
    final userId = _supabaseService.client?.auth.currentUser?.id;
    if (userId != null && userId.isNotEmpty) {
      await syncUserFcmToken(userId);
    }
  }
}
