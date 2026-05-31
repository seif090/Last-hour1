import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';

class MerchantWebSocketService {
  WebSocketChannel? _channel;
  final BehaviorSubject<Map<String, dynamic>> _incomingOrders =
      BehaviorSubject<Map<String, dynamic>>();
  final BehaviorSubject<Map<String, dynamic>> _stockAlerts =
      BehaviorSubject<Map<String, dynamic>>();
  StreamSubscription? _subscription;
  Timer? _pingTimer;

  Stream<Map<String, dynamic>> get incomingOrders => _incomingOrders.stream;
  Stream<Map<String, dynamic>> get stockAlerts => _stockAlerts.stream;

  final String _baseUrl;
  final String _token;
  final String _storeId;

  MerchantWebSocketService({
    required String baseUrl,
    required String token,
    required String storeId,
  })  : _baseUrl = baseUrl,
        _token = token,
        _storeId = storeId;

  Future<void> connect() async {
    final uri = Uri.parse('$_baseUrl/ws?token=$_token');
    _channel = WebSocketChannel.connect(uri);

    _subscription = _channel!.stream.listen(
      (data) {
        final message = jsonDecode(data as String) as Map<String, dynamic>;
        _handleMessage(message);
      },
      onError: (_) => _reconnect(),
      onDone: () => _reconnect(),
    );

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _ping());

    // Subscribe to store channel
    subscribe('offer:store:$_storeId');
  }

  void _handleMessage(Map<String, dynamic> message) {
    final event = message['event'] as String;

    switch (event) {
      case 'order:status':
        if (message['order_id'] != null) {
          _incomingOrders.add(message);
        }
      case 'stock:update':
        _stockAlerts.add(message);
      case 'offer:expired':
      case 'offer:sold_out':
        _stockAlerts.add(message);
    }
  }

  void subscribe(String channel) {
    _channel?.sink.add(jsonEncode({
      'event': 'subscribe',
      'payload': {'channel': channel},
    }));
  }

  void unsubscribe(String channel) {
    _channel?.sink.add(jsonEncode({
      'event': 'unsubscribe',
      'payload': {'channel': channel},
    }));
  }

  void _ping() {
    _channel?.sink.add(jsonEncode({'event': 'ping'}));
  }

  void _reconnect() {
    _pingTimer?.cancel();
    Future.delayed(const Duration(seconds: 3), connect);
  }

  void dispose() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _incomingOrders.close();
    _stockAlerts.close();
  }
}
