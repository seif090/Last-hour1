import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../services/api_client.dart';
import '../../../../services/websocket_service.dart';

abstract class IncomingOrdersEvent extends Equatable {
  const IncomingOrdersEvent();
  @override
  List<Object?> get props => [];
}

class LoadIncomingOrders extends IncomingOrdersEvent {}

class NewOrderReceived extends IncomingOrdersEvent {
  final OrderItem order;
  const NewOrderReceived(this.order);
}

class AcceptOrder extends IncomingOrdersEvent {
  final String orderId;
  const AcceptOrder(this.orderId);
}

class MarkReady extends IncomingOrdersEvent {
  final String orderId;
  const MarkReady(this.orderId);
}

// ─── State ──────────────────────────────────────────────────────
abstract class IncomingOrdersState extends Equatable {
  const IncomingOrdersState();
  @override
  List<Object?> get props => [];
}

class IncomingOrdersInitial extends IncomingOrdersState {}

class IncomingOrdersLoading extends IncomingOrdersState {}

class IncomingOrdersLoaded extends IncomingOrdersState {
  final List<OrderItem> orders;
  final int pendingCount;

  const IncomingOrdersLoaded({
    required this.orders,
    required this.pendingCount,
  });

  IncomingOrdersLoaded copyWith({
    List<OrderItem>? orders,
    int? pendingCount,
  }) {
    return IncomingOrdersLoaded(
      orders: orders ?? this.orders,
      pendingCount: pendingCount ?? this.pendingCount,
    );
  }

  @override
  List<Object?> get props => [orders, pendingCount];
}

class IncomingOrdersError extends IncomingOrdersState {
  final String message;
  const IncomingOrdersError(this.message);
}

class OrderItem extends Equatable {
  final String id;
  final String orderNumber;
  final String customerName;
  final String status;
  final int quantity;
  final String productName;
  final double total;
  final DateTime createdAt;
  final String? estimatedReadyAt;

  const OrderItem({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.status,
    required this.quantity,
    required this.productName,
    required this.total,
    required this.createdAt,
    this.estimatedReadyAt,
  });

  @override
  List<Object?> get props => [id, status];
}

// ─── BLoC ───────────────────────────────────────────────────────
class IncomingOrdersBloc extends Bloc<IncomingOrdersEvent, IncomingOrdersState> {
  final ApiClient _api;
  final MerchantWebSocketService _ws;
  StreamSubscription? _wsSubscription;

  IncomingOrdersBloc({
    required ApiClient api,
    required MerchantWebSocketService ws,
  })  : _api = api,
        _ws = ws,
        super(IncomingOrdersInitial()) {
    on<LoadIncomingOrders>(_onLoad);
    on<NewOrderReceived>(_onNewOrder);
    on<AcceptOrder>(_onAccept);
    on<MarkReady>(_onMarkReady);

    _wsSubscription = _ws.incomingOrders.listen((message) {
      if (message['event'] == 'order:status') {
        final order = OrderItem(
          id: message['order_id'] as String,
          orderNumber: message['order_number'] as String? ?? '',
          customerName: message['customer_name'] as String? ?? 'Customer',
          status: message['status'] as String,
          quantity: message['quantity'] as int? ?? 1,
          productName: message['product_name'] as String? ?? '',
          total: (message['total'] as num?)?.toDouble() ?? 0,
          createdAt: DateTime.now(),
        );
        add(NewOrderReceived(order));
      }
    });
  }

  Future<void> _onLoad(LoadIncomingOrders event, Emitter<IncomingOrdersState> emit) async {
    emit(IncomingOrdersLoading());

    try {
      final response = await _api.get('/api/v1/merchant/orders');

      if (response.isSuccess && response.data != null) {
        final orders = (response.data!['orders'] as List)
            .map((j) => OrderItem(
                  id: j['id'],
                  orderNumber: j['order_number'],
                  customerName: j['customer_name'] ?? 'Customer',
                  status: j['status'],
                  quantity: j['quantity'],
                  productName: j['product_name'],
                  total: (j['total_amount'] as num).toDouble(),
                  createdAt: DateTime.parse(j['created_at']),
                  estimatedReadyAt: j['estimated_ready_at'] as String?,
                ))
            .toList();

        emit(IncomingOrdersLoaded(
          orders: orders,
          pendingCount: orders.where((o) => o.status == 'pending').length,
        ));
      }
    } catch (e) {
      emit(IncomingOrdersError(e.toString()));
    }
  }

  Future<void> _onNewOrder(NewOrderReceived event, Emitter<IncomingOrdersState> emit) {
    if (state is IncomingOrdersLoaded) {
      final current = state as IncomingOrdersLoaded;
      emit(current.copyWith(
        orders: [event.order, ...current.orders],
        pendingCount: current.pendingCount + 1,
      ));
    }
  }

  Future<void> _onAccept(AcceptOrder event, Emitter<IncomingOrdersState> emit) async {
    try {
      await _api.patch('/api/v1/merchant/orders/${event.orderId}/status', body: {
        'status': 'confirmed',
      });

      if (state is IncomingOrdersLoaded) {
        final current = state as IncomingOrdersLoaded;
        final updated = current.orders.map((o) {
          if (o.id == event.orderId) {
            return OrderItem(
              id: o.id,
              orderNumber: o.orderNumber,
              customerName: o.customerName,
              status: 'confirmed',
              quantity: o.quantity,
              productName: o.productName,
              total: o.total,
              createdAt: o.createdAt,
            );
          }
          return o;
        }).toList();

        emit(current.copyWith(
          orders: updated,
          pendingCount: updated.where((o) => o.status == 'pending').length,
        ));
      }
    } catch (_) {}
  }

  Future<void> _onMarkReady(MarkReady event, Emitter<IncomingOrdersState> emit) async {
    try {
      await _api.patch('/api/v1/merchant/orders/${event.orderId}/status', body: {
        'status': 'ready',
      });

      if (state is IncomingOrdersLoaded) {
        final current = state as IncomingOrdersLoaded;
        final updated = current.orders.map((o) {
          if (o.id == event.orderId) {
            return OrderItem(
              id: o.id,
              orderNumber: o.orderNumber,
              customerName: o.customerName,
              status: 'ready',
              quantity: o.quantity,
              productName: o.productName,
              total: o.total,
              createdAt: o.createdAt,
            );
          }
          return o;
        }).toList();

        emit(current.copyWith(orders: updated));
      }
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
