import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../firebase_options.dart';
import '../network/dio_client.dart';

/// Wraps Firebase Cloud Messaging: registers the device token with the
/// backend after login, and routes notification taps to the relevant
/// ticket or work order.
///
/// Every step is wrapped so that a missing/placeholder Firebase project
/// (see firebase_options.dart) makes this a silent no-op instead of
/// crashing the app — the rest of the GMAO app works normally either way.
class PushService {
  static bool _initialized = false;

  static Future<void> initialize(GoRouter router) async {
    if (_initialized) return;
    _initialized = true;

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      messaging.onTokenRefresh.listen(_registerToken);
      FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleTap(router, message));

      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleTap(router, initialMessage);
      }

      await registerCurrentToken();
    } catch (e) {
      // Covers a not-yet-configured Firebase project (see firebase_options.dart)
      // as well as platforms without an FCM plugin implementation (e.g. Windows
      // desktop, used here only for dev convenience — real targets are
      // Android/iOS).
      debugPrint('Notifications push indisponibles sur cette plateforme : $e');
    }
  }

  /// Sends the current device's FCM token to the backend. Call after login.
  static Future<void> registerCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (e) {
      debugPrint('Impossible de récupérer le token FCM : $e');
    }
  }

  static Future<void> _registerToken(String token) async {
    try {
      await DioClient.instance.post('/auth/fcm-token', data: {'fcm_token': token});
    } catch (e) {
      debugPrint("Échec de l'enregistrement du token FCM : $e");
    }
  }

  /// Clears the token server-side on logout so this device stops receiving
  /// notifications meant for whoever logs in next.
  static Future<void> clearToken() async {
    try {
      await DioClient.instance.post('/auth/fcm-token', data: {'fcm_token': null});
    } catch (_) {
      // Best-effort — a failed clear on logout isn't worth surfacing to the user.
    }
  }

  static void _handleTap(GoRouter router, RemoteMessage message) {
    final ticketId = message.data['ticket_id'];
    final workOrderId = message.data['work_order_id'];

    if (ticketId != null) {
      router.push('/tickets/$ticketId');
    } else if (workOrderId != null) {
      router.push('/');
    }
  }
}
