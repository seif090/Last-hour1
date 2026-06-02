import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lasthour_shared/models/order.dart';
import '../../../services/api_client.dart';
import '../../../services/websocket_service.dart';

abstract class IncomingOrdersEvent extends Equatable {
  const IncomingOrdersEvent();
  @override
  List<Object?> get props => [];
}

class LoadIncomingOrders extends IncomingOrdersEvent {
  final bool refresh;
  const LoadIncomingOrders({this.refresh = true});
}
class LoadMoreOrders extends IncomingOrdersEvent {}
class AcceptOrder extends IncomingOrdersEvent {
  final String orderId;
  const AcceptOrder(this.orderId);
}
class MarkReady extends IncomingOrdersEvent {
  final String orderId;
  const MarkReady(this.orderId);
}
class NewOrderReceived extends IncomingOrdersEvent {
  final Order order;
  const NewOrderReceived(this.order);
}
class OrderStatusChanged extends IncomingOrdersEvent {
  final String orderId;
  final String status;
  const OrderStatusChanged(this.orderId, this.status);
}

abstract class IncomingOrdersState extends Equatable {
  const IncomingOrdersState();
  @override
  List<Object?> get props => [];
}

class IncomingOrdersInitial extends IncomingOrdersState {}
class IncomingOrdersLoading extends IncomingOrdersState {}
class IncomingOrdersLoaded extends IncomingOrdersState {
  final List<Order> orders;
  final bool hasMore;
  final bool isLoadingMore;
  final int page;
  const IncomingOrdersLoaded({
    this.orders = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.page = 1,
  });

  IncomingOrdersLoaded copyWith({
    List<Order>? orders,
    bool? hasMore,
    bool? isLoadingMore,
    int? page,
  }) {
    return IncomingOrdersLoaded(
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [orders, hasMore, isLoadingMore, page];
}
class IncomingOrdersError extends IncomingOrdersState {
  final String message;
  const IncomingOrdersError(this.message);
  @override
  List<Object?> get props => [message];
}
class OrderActionSuccess extends IncomingOrdersState {
  final String message;
  const OrderActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class IncomingOrdersBloc extends Bloc<IncomingOrdersEvent, IncomingOrdersState> {
  final ApiClient _api;
  final MerchantWebSocketService _ws;
  StreamSubscription? _wsSub;

  IncomingOrdersBloc({required ApiClient api, required MerchantWebSocketService ws})
      : _api = api,
        _ws = ws,
        super(IncomingOrdersInitial()) {
    on<LoadIncomingOrders>(_onLoad);
    on<LoadMoreOrders>(_onLoadMore);
    on<AcceptOrder>(_onAccept);
    on<MarkReady>(_onMarkReady);
    on<NewOrderReceived>(_onNewOrder);
    on<OrderStatusChanged>(_onStatusChanged);

    _setupWebSocket();
  }

  void _setupWebSocket() {
    _ws.connect();
    _wsSub = _ws.messages.listen((msg) {
      final event = msg['event'] as String?;
      final data = msg['data'] as Map<String, dynamic>? ?? {};

      if (event == 'order:new') {
        add(NewOrderReceived(Order.fromJson(data)));
      } else if (event == 'order:update') {
        add(OrderStatusChanged(data['order_id'] as String, data['status'] as String));
      }
    });
  }

  Future<void> _onLoad(LoadIncomingOrders event, Emitter<IncomingOrdersState> emit) async {
    if (event.refresh) emit(IncomingOrdersLoading());

    try {
      final page = event.refresh ? 1 : (state is IncomingOrdersLoaded ? (state as IncomingOrdersLoaded).page + 1 : 1);
      final response = await _api.get('/api/v1/merchant/orders', queryParams: {
        'page': page.toString(),
        'limit': '20',
      });
      if (response.isSuccess && response.data != null) {
        final orders = (response.data!['orders'] as List? ?? [])
            .map((j) => Order.fromJson(j as Map<String, dynamic>))
            .toList();
        final meta = response.data!['meta'] as Map<String, dynamic>? ?? {};
        final hasMore = meta['hasMore'] as bool? ?? false;

        if (event.refresh) {
          emit(IncomingOrdersLoaded(orders: orders, hasMore: hasMore, page: page));
        } else {
          final current = state as IncomingOrdersLoaded;
          emit(IncomingOrdersLoaded(
            orders: [...current.orders, ...orders],
            hasMore: hasMore,
            page: page,
          ));
        }
      } else {
        emit(IncomingOrdersError(response.error ?? 'Failed to load orders'));
      }
    } catch (e) {
      emit(IncomingOrdersError(e.toString()));
    }
  }

  Future<void> _onLoadMore(LoadMoreOrders event, Emitter<IncomingOrdersState> emit) async {
    if (state is! IncomingOrdersLoaded) return;
    final current = state as IncomingOrdersLoaded;
    if (current.isLoadingMore || !current.hasMore) return;
    add(const LoadIncomingOrders(refresh: false));
  }

  Future<void> _onAccept(AcceptOrder event, Emitter<IncomingOrdersState> emit) async {
    try {
      final response = await _api.patch('/api/v1/merchant/orders/${event.orderId}/status', body: {
        'status': 'confirmed',
      });
      if (response.isSuccess) {
        emit(const OrderActionSuccess('Order accepted'));
        add(const LoadIncomingOrders());
      } else {
        emit(IncomingOrdersError(response.error ?? 'Failed to accept'));
      }
    } catch (e) {
      emit(IncomingOrdersError(e.toString()));
    }
  }

  Future<void> _onMarkReady(MarkReady event, Emitter<IncomingOrdersState> emit) async {
    try {
      final response = await _api.patch('/api/v1/merchant/orders/${event.orderId}/status', body: {
        'status': 'ready',
      });
      if (response.isSuccess) {
        emit(const OrderActionSuccess('Order marked ready'));
        add(const LoadIncomingOrders());
      } else {
        emit(IncomingOrdersError(response.error ?? 'Failed to update'));
      }
    } catch (e) {
      emit(IncomingOrdersError(e.toString()));
    }
  }

  void _onNewOrder(NewOrderReceived event, Emitter<IncomingOrdersState> emit) {
    if (state is IncomingOrdersLoaded) {
      final current = state as IncomingOrdersLoaded;
      emit(IncomingOrdersLoaded(orders: [event.order, ...current.orders], hasMore: current.hasMore, page: current.page));
    }
  }

  void _onStatusChanged(OrderStatusChanged event, Emitter<IncomingOrdersState> emit) {
    if (state is IncomingOrdersLoaded) {
      final current = state as IncomingOrdersLoaded;
      final merged = current.orders.map((o) {
        if (o.id == event.orderId) {
          return Order(
            id: o.id, orderNumber: o.orderNumber, status: event.status,
            quantity: o.quantity, subtotal: o.subtotal, serviceFee: o.serviceFee,
            totalAmount: o.totalAmount, discountAmount: o.discountAmount,
            couponCode: o.couponCode, currency: o.currency,
            estimatedReadyAt: o.estimatedReadyAt, storeId: o.storeId,
            storeName: o.storeName,
            storeAddress: o.storeAddress, storeLat: o.storeLat, storeLng: o.storeLng,
            offerId: o.offerId, offerTitle: o.offerTitle, offerImageUrl: o.offerImageUrl,
            createdAt: o.createdAt, statusHistory: o.statusHistory,
          );
        }
        return o;
      }).toList();
      emit(IncomingOrdersLoaded(orders: merged, hasMore: current.hasMore, page: current.page));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
