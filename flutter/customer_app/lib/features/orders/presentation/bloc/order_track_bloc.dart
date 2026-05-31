import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../services/api_client.dart';
import '../../../services/websocket_service.dart';

// ─── Events ─────────────────────────────────────────────────────
abstract class OrderTrackEvent extends Equatable {
  const OrderTrackEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrder extends OrderTrackEvent {
  final String orderId;
  const LoadOrder(this.orderId);
}

class OrderStatusUpdated extends OrderTrackEvent {
  final String status;
  final DateTime? estimatedReadyAt;
  const OrderStatusUpdated(this.status, this.estimatedReadyAt);
}

class StartTracking extends OrderTrackEvent {
  final String orderId;
  const StartTracking(this.orderId);
}

class StopTracking extends OrderTrackEvent {}

// ─── State ──────────────────────────────────────────────────────
abstract class OrderTrackState extends Equatable {
  const OrderTrackState();
  @override
  List<Object?> get props => [];
}

class OrderTrackInitial extends OrderTrackState {}

class OrderTrackLoading extends OrderTrackState {}

class OrderTrackLoaded extends OrderTrackState {
  final String orderId;
  final String orderNumber;
  final String status;
  final List<StatusHistoryItem> statusHistory;
  final DateTime? estimatedReadyAt;
  final String storeName;
  final String storeAddress;
  final double storeLat;
  final double storeLng;
  final int quantity;
  final double totalAmount;

  const OrderTrackLoaded({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.statusHistory,
    this.estimatedReadyAt,
    required this.storeName,
    required this.storeAddress,
    required this.storeLat,
    required this.storeLng,
    required this.quantity,
    required this.totalAmount,
  });

  OrderTrackLoaded copyWith({
    String? status,
    List<StatusHistoryItem>? statusHistory,
    DateTime? estimatedReadyAt,
  }) {
    return OrderTrackLoaded(
      orderId: orderId,
      orderNumber: orderNumber,
      status: status ?? this.status,
      statusHistory: statusHistory ?? this.statusHistory,
      estimatedReadyAt: estimatedReadyAt ?? this.estimatedReadyAt,
      storeName: storeName,
      storeAddress: storeAddress,
      storeLat: storeLat,
      storeLng: storeLng,
      quantity: quantity,
      totalAmount: totalAmount,
    );
  }

  @override
  List<Object?> get props =>
      [orderId, status, statusHistory, estimatedReadyAt];
}

class OrderTrackError extends OrderTrackState {
  final String message;
  const OrderTrackError(this.message);
}

class StatusHistoryItem extends Equatable {
  final String status;
  final DateTime at;

  const StatusHistoryItem({required this.status, required this.at});

  @override
  List<Object?> get props => [status, at];
}

// ─── BLoC ───────────────────────────────────────────────────────
class OrderTrackBloc extends Bloc<OrderTrackEvent, OrderTrackState> {
  final ApiClient _api;
  final WebSocketService _ws;
  StreamSubscription? _wsSubscription;

  OrderTrackBloc({
    required ApiClient api,
    required WebSocketService ws,
  })  : _api = api,
        _ws = ws,
        super(OrderTrackInitial()) {
    on<LoadOrder>(_onLoadOrder);
    on<OrderStatusUpdated>(_onStatusUpdated);
    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
  }

  Future<void> _onLoadOrder(LoadOrder event, Emitter<OrderTrackState> emit) async {
    emit(OrderTrackLoading());

    try {
      final response = await _api.get('/api/v1/orders/${event.orderId}/track');

      if (response.isSuccess && response.data != null) {
        final d = response.data!;
        final history = (d['status_history'] as List)
            .map((h) => StatusHistoryItem(
                  status: h['status'] as String,
                  at: DateTime.parse(h['at'] as String),
                ))
            .toList();

        emit(OrderTrackLoaded(
          orderId: d['order_id'] as String,
          orderNumber: d['order_number'] as String,
          status: d['status'] as String,
          statusHistory: history,
          estimatedReadyAt: d['estimated_ready_at'] != null
              ? DateTime.parse(d['estimated_ready_at'] as String)
              : null,
          storeName: d['store']['name'] as String,
          storeAddress: d['store']['address'] as String,
          storeLat: (d['store']['lat'] as num).toDouble(),
          storeLng: (d['store']['lng'] as num).toDouble(),
          quantity: d['quantity'] as int,
          totalAmount: (d['total_amount'] as num).toDouble(),
        ));

        // Subscribe to real-time updates
        add(StartTracking(event.orderId));
      } else {
        emit(OrderTrackError(response.error ?? 'Order not found'));
      }
    } catch (e) {
      emit(OrderTrackError(e.toString()));
    }
  }

  void _onStartTracking(StartTracking event, Emitter<OrderTrackState> emit) {
    _ws.subscribe('order:${event.orderId}');
    _wsSubscription?.cancel();
    _wsSubscription = _ws.watchOrderStatus(event.orderId).listen((status) {
      add(OrderStatusUpdated(status, null));
    });
  }

  void _onStatusUpdated(
      OrderStatusUpdated event, Emitter<OrderTrackState> emit) {
    if (state is OrderTrackLoaded) {
      final current = state as OrderTrackLoaded;
      final updatedHistory = [
        ...current.statusHistory,
        StatusHistoryItem(
          status: event.status,
          at: DateTime.now(),
        ),
      ];

      emit(current.copyWith(
        status: event.status,
        statusHistory: updatedHistory,
        estimatedReadyAt: event.estimatedReadyAt ?? current.estimatedReadyAt,
      ));
    }
  }

  void _onStopTracking(StopTracking event, Emitter<OrderTrackState> emit) {
    _wsSubscription?.cancel();
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
