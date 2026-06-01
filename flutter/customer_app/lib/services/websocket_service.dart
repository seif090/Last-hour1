import 'dart:async';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final String baseUrl;
  String token;
  WebSocketChannel? _channel;
  final _messageController = BehaviorSubject<Map<String, dynamic>>();
  final _connectionStatus = BehaviorSubject<bool>.seeded(false);
  StreamSubscription? _subscription;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionStatus.stream;

  WebSocketService({required this.baseUrl, required this.token});

  void updateToken(String newToken) {
    token = newToken;
    if (isConnected) {
      _channel?.sink.close();
      _channel = null;
      _connectionStatus.add(false);
      connect();
    }
  }

  bool get isConnected => _connectionStatus.value;

  Future<void> connect({String? room}) async {
    final uri = Uri.parse('$baseUrl?token=$token${room != null ? '&room=$room' : ''}');
    try {
      _channel = WebSocketChannel.connect(uri);
      _connectionStatus.add(true);

      _subscription = _channel!.stream.listen(
        (data) {
          try {
            final parsed = jsonDecode(data as String) as Map<String, dynamic>;
            _messageController.add(parsed);
          } catch (_) {}
        },
        onError: (error) {
          _connectionStatus.add(false);
          _scheduleReconnect(room);
        },
        onDone: () {
          _connectionStatus.add(false);
          _scheduleReconnect(room);
        },
      );
    } catch (_) {
      _connectionStatus.add(false);
      _scheduleReconnect(room);
    }
  }

  void _scheduleReconnect(String? room) {
    Future.delayed(const Duration(seconds: 3), () {
      if (!isConnected) connect(room: room);
    });
  }

  void send(String event, {Map<String, dynamic>? payload}) {
    if (_channel != null && isConnected) {
      _channel!.sink.add(jsonEncode({
        'event': event,
        'data': payload ?? {},
      }));
    }
  }

  void subscribe(String channel) {
    send('subscribe', payload: {'channel': channel});
  }

  void unsubscribe(String channel) {
    send('unsubscribe', payload: {'channel': channel});
  }

  Stream<Map<String, dynamic>> onEvent(String event) {
    return _messageController.stream.where((m) => m['event'] == event);
  }

  void dispose() {
    _subscription?.cancel();
    _channel?.sink.close();
    _messageController.close();
    _connectionStatus.close();
  }
}

class WsEvent {
  static const String stockUpdate = 'stock:update';
  static const String orderUpdate = 'order:update';
  static const String offerExpired = 'offer:expired';
  static const String newOffer = 'offer:new';
  static const String orderPlaced = 'order:placed';
  static const String orderConfirmed = 'order:confirmed';
  static const String orderReady = 'order:ready';
}
