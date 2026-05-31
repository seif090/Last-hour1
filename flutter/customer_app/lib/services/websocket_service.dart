import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:rxdart/rxdart.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  final BehaviorSubject<Map<String, dynamic>> _offerFeed =
      BehaviorSubject<Map<String, dynamic>>();
  final BehaviorSubject<Map<String, dynamic>> _orderUpdates =
      BehaviorSubject<Map<String, dynamic>>();
  StreamSubscription? _subscription;

  Stream<Map<String, dynamic>> get offerFeed => _offerFeed.stream;
  Stream<Map<String, dynamic>> get orderUpdates => _orderUpdates.stream;

  final String _baseUrl;
  final String _token;
  Timer? _pingTimer;

  WebSocketService({required String baseUrl, required String token})
      : _baseUrl = baseUrl,
        _token = token;

  Future<void> connect() async {
    final uri = Uri.parse('$_baseUrl/ws?token=$_token');
    _channel = WebSocketChannel.connect(uri);

    _subscription = _channel!.stream.listen(
      (data) {
        final message = jsonDecode(data as String) as Map<String, dynamic>;
        _handleMessage(message);
      },
      onError: (error) {
        _offerFeed.addError(error);
        _reconnect();
      },
      onDone: () => _reconnect(),
    );

    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) => _ping());
  }

  void _handleMessage(Map<String, dynamic> message) {
    final event = message['event'] as String;

    switch (event) {
      case 'stock:update':
        _offerFeed.add(message);
      case 'order:status':
        _orderUpdates.add(message);
      case 'offer:created':
        _offerFeed.add(message);
      case 'offer:expired':
      case 'offer:sold_out':
        _offerFeed.add(message);
      case 'pong':
        break;
      default:
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

  Stream<int> watchStock(String offerId) {
    return _offerFeed.stream
        .where((msg) => msg['offer_id'] == offerId)
        .map((msg) => msg['stock_remaining'] as int);
  }

  Stream<String> watchOrderStatus(String orderId) {
    return _orderUpdates.stream
        .where((msg) => msg['order_id'] == orderId)
        .map((msg) => msg['status'] as String);
  }

  void dispose() {
    _pingTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _offerFeed.close();
    _orderUpdates.close();
  }
}
