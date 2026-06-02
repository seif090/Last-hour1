import 'dart:async';
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class MerchantWebSocketService {
  final String baseUrl;
  String token;
  String merchantId;
  WebSocketChannel? _channel;
  final _messageController = BehaviorSubject<Map<String, dynamic>>();
  final _connectionStatus = BehaviorSubject<bool>.seeded(false);
  StreamSubscription<dynamic>? _subscription;

  Stream<Map<String, dynamic>> get messages => _messageController.stream;
  Stream<bool> get connectionStatus => _connectionStatus.stream;

  MerchantWebSocketService({
    required this.baseUrl,
    required this.token,
    required this.merchantId,
  });

  void updateCredentials({required String token, required String merchantId}) {
    this.token = token;
    this.merchantId = merchantId;
    if (isConnected) {
      _channel?.sink.close();
      _channel = null;
      _connectionStatus.add(false);
      connect();
    }
  }

  bool get isConnected => _connectionStatus.value;

  Future<void> connect() async {
    final uri = Uri.parse('$baseUrl?token=$token&room=merchant:$merchantId');
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
        onError: (_) {
          _connectionStatus.add(false);
          _scheduleReconnect();
        },
        onDone: () {
          _connectionStatus.add(false);
          _scheduleReconnect();
        },
      );
    } catch (_) {
      _connectionStatus.add(false);
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!isConnected) connect();
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
