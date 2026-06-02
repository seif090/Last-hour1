import 'dart:async';
import '../services/api_client.dart';

typedef NavigationCallback = void Function(String route, {Map<String, String>? params});

class NotificationService {
  final ApiClient _api;
  String? _currentToken;

  /// Callback for deep-link navigation
  NavigationCallback? onNavigate;

  NotificationService(this._api);

  Future<void> registerToken(String token, String platform) async {
    _currentToken = token;
    try {
      await _api.post('/api/v1/device-tokens', body: {
        'token': token,
        'platform': platform,
      });
    } catch (_) {}
  }

  Future<void> unregisterToken() async {
    if (_currentToken == null) return;
    try {
      await _api.delete('/api/v1/device-tokens/${_currentToken!}');
    } catch (_) {}
    _currentToken = null;
  }

  String? get currentToken => _currentToken;

  /// Handle notification data payload for deep-link navigation.
  /// Called when user taps a push notification.
  void handleData(Map<String, String> data) {
    final screen = data['screen'];
    if (screen == null) return;

    switch (screen) {
      case 'order-tracking':
        final orderId = data['orderId'];
        if (orderId != null) {
          onNavigate?.call('/orders/$orderId/track');
        }
      case 'offers-nearby':
        onNavigate?.call('/map');
      default:
        onNavigate?.call('/');
    }
  }
}
