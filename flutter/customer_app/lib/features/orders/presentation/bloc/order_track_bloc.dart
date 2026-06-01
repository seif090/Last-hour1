import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lasthour_shared/models/order.dart';
import '../../../../services/api_client.dart';
import '../../../../services/websocket_service.dart';

abstract class OrderTrackEvent extends Equatable {
  const OrderTrackEvent();
  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrderTrackEvent {}
class LoadOrderDetail extends OrderTrackEvent {
  final String orderId;
  const LoadOrderDetail(this.orderId);
}
class OrderStatusUpdated extends OrderTrackEvent {
  final String orderId;
  final String status;
  final String? estimatedReadyAt;
  const OrderStatusUpdated(this.orderId, this.status, {this.estimatedReadyAt});
}

abstract class OrderTrackState extends Equatable {
  const OrderTrackState();
  @override
  List<Object?> get props => [];
}

class OrderTrackInitial extends OrderTrackState {}
class OrdersLoading extends OrderTrackState {}
class OrdersLoaded extends OrderTrackState {
  final List<Order> orders;
  const OrdersLoaded({this.orders = const []});
  @override
  List<Object?> get props => [orders];
}
class OrderDetailLoaded extends OrderTrackState {
  final Order order;
  const OrderDetailLoaded(this.order);
  @override
  List<Object?> get props => [order];
}
class OrderTrackError extends OrderTrackState {
  final String message;
  const OrderTrackError(this.message);
  @override
  List<Object?> get props => [message];
}

class OrderTrackBloc extends Bloc<OrderTrackEvent, OrderTrackState> {
  final ApiClient _api;
  final WebSocketService _ws;
  StreamSubscription? _wsSub;

  OrderTrackBloc({required ApiClient api, required WebSocketService ws})
      : _api = api,
        _ws = ws,
        super(OrderTrackInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<LoadOrderDetail>(_onLoadDetail);
    on<OrderStatusUpdated>(_onStatusUpdated);

    _wsSub = _ws.onEvent('order:update').listen((msg) {
      final data = msg['data'] as Map<String, dynamic>;
      add(OrderStatusUpdated(
        data['order_id'] as String,
        data['status'] as String,
        estimatedReadyAt: data['estimated_ready_at'] as String?,
      ));
    });
  }

  Future<void> _onLoadOrders(LoadOrders event, Emitter<OrderTrackState> emit) async {
    emit(OrdersLoading());
    try {
      final response = await _api.get('/api/v1/orders');
      if (response.isSuccess && response.data != null) {
        final orders = (response.data!['orders'] as List? ?? [])
            .map((j) => Order.fromJson(j as Map<String, dynamic>))
            .toList();
        emit(OrdersLoaded(orders: orders));
      } else {
        emit(OrderTrackError(response.error ?? 'Failed to load orders'));
      }
    } catch (e) {
      emit(OrderTrackError(e.toString()));
    }
  }

  Future<void> _onLoadDetail(LoadOrderDetail event, Emitter<OrderTrackState> emit) async {
    emit(OrderTrackInitial());
    try {
      final response = await _api.get('/api/v1/orders/${event.orderId}');
      if (response.isSuccess && response.data != null) {
        final order = Order.fromJson(response.data!['order'] as Map<String, dynamic>? ?? response.data!);
        emit(OrderDetailLoaded(order));
      } else {
        emit(OrderTrackError(response.error ?? 'Order not found'));
      }
    } catch (e) {
      emit(OrderTrackError(e.toString()));
    }
  }

  void _onStatusUpdated(OrderStatusUpdated event, Emitter<OrderTrackState> emit) {
    if (state is OrderDetailLoaded) {
      final current = state as OrderDetailLoaded;
      if (current.order.id == event.orderId) {
        final updatedHistory = [
          ...current.order.statusHistory,
          StatusHistory(status: event.status, at: DateTime.now()),
        ];
        emit(OrderDetailLoaded(Order(
          id: current.order.id,
          orderNumber: current.order.orderNumber,
          status: event.status,
          quantity: current.order.quantity,
          subtotal: current.order.subtotal,
          serviceFee: current.order.serviceFee,
          totalAmount: current.order.totalAmount,
          currency: current.order.currency,
          estimatedReadyAt: event.estimatedReadyAt ?? current.order.estimatedReadyAt,
          storeName: current.order.storeName,
          storeAddress: current.order.storeAddress,
          storeLat: current.order.storeLat,
          storeLng: current.order.storeLng,
          offerTitle: current.order.offerTitle,
          offerImageUrl: current.order.offerImageUrl,
          createdAt: current.order.createdAt,
          statusHistory: updatedHistory,
        )));
      }
    }

    if (state is OrdersLoaded) {
      final current = state as OrdersLoaded;
      final updated = current.orders.map((o) {
        if (o.id == event.orderId) {
          return Order(
            id: o.id,
            orderNumber: o.orderNumber,
            status: event.status,
            quantity: o.quantity,
            subtotal: o.subtotal,
            serviceFee: o.serviceFee,
            totalAmount: o.totalAmount,
            currency: o.currency,
            estimatedReadyAt: event.estimatedReadyAt ?? o.estimatedReadyAt,
            storeName: o.storeName,
            storeAddress: o.storeAddress,
            storeLat: o.storeLat,
            storeLng: o.storeLng,
            offerTitle: o.offerTitle,
            offerImageUrl: o.offerImageUrl,
            createdAt: o.createdAt,
            statusHistory: o.statusHistory,
          );
        }
        return o;
      }).toList();
      emit(OrdersLoaded(orders: updated));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
