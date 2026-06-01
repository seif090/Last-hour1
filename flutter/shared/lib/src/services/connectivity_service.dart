import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  Stream<bool> get connectivityStream => _controller.stream;

  void initialize() {
    _connectivity.checkConnectivity().then((results) {
      _isConnected = !results.contains(ConnectivityResult.none);
      _controller.add(_isConnected);
    });
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _isConnected = !results.contains(ConnectivityResult.none);
      _controller.add(_isConnected);
    });
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
