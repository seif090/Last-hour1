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

class LoadOrders extends OrderTrackEvent {
  final bool refresh;
  final String? status;
  final String? startDate;
  final String? endDate;
  final double? minPrice;
  final double? maxPrice;
  final String? sort;
  const LoadOrders({
    this.refresh = true,
    this.status,
    this.startDate,
    this.endDate,
    this.minPrice,
    this.maxPrice,
    this.sort,
  });
}
class LoadMoreOrders extends OrderTrackEvent {}
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
class ConfirmPickup extends OrderTrackEvent {
  final String orderId;
  const ConfirmPickup(this.orderId);
}
class CancelOrder extends OrderTrackEvent {
  final String orderId;
  final String? reason;
  const CancelOrder(this.orderId, {this.reason});
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
  final bool hasMore;
  final bool isLoadingMore;
  final int page;
  const OrdersLoaded({
    this.orders = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.page = 1,
  });

  OrdersLoaded copyWith({
    List<Order>? orders,
    bool? hasMore,
    bool? isLoadingMore,
    int? page,
  }) {
    return OrdersLoaded(
      orders: orders ?? this.orders,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [orders, hasMore, isLoadingMore, page];
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
  String? _status;
  String? _startDate;
  String? _endDate;
  double? _minPrice;
  double? _maxPrice;
  String? _sort;

  OrderTrackBloc({required ApiClient api, required WebSocketService ws})
      : _api = api,
        _ws = ws,
        super(OrderTrackInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<LoadMoreOrders>(_onLoadMore);
    on<LoadOrderDetail>(_onLoadDetail);
    on<OrderStatusUpdated>(_onStatusUpdated);
    on<ConfirmPickup>(_onConfirmPickup);
    on<CancelOrder>(_onCancelOrder);

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
    _status = event.status;
    _startDate = event.startDate;
    _endDate = event.endDate;
    _minPrice = event.minPrice;
    _maxPrice = event.maxPrice;
    _sort = event.sort;

    final page = event.refresh ? 1 : (state is OrdersLoaded ? (state as OrdersLoaded).page + 1 : 1);

    if (event.refresh) {
      emit(const OrdersLoading());
    } else if (state is OrdersLoaded) {
      emit((state as OrdersLoaded).copyWith(isLoadingMore: true));
    }

    try {
      final params = <String, String>{'page': page.toString(), 'limit': '20'};
      if (_status != null) params['status'] = _status!;
      if (_startDate != null) params['startDate'] = _startDate!;
      if (_endDate != null) params['endDate'] = _endDate!;
      if (_minPrice != null) params['minPrice'] = _minPrice.toString();
      if (_maxPrice != null) params['maxPrice'] = _maxPrice.toString();
      if (_sort != null) params['sort'] = _sort!;
      final qs = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
      final response = await _api.get('/api/v1/orders${qs.isNotEmpty ? '?$qs' : ''}');
      if (response.isSuccess && response.data != null) {
        final orders = (response.data!['orders'] as List? ?? [])
            .map((j) => Order.fromJson(j as Map<String, dynamic>))
            .toList();
        final meta = response.data!['meta'] as Map<String, dynamic>? ?? {};
        final hasMore = meta['hasMore'] as bool? ?? false;
        final total = meta['total'] as int? ?? 0;

        if (event.refresh) {
          emit(OrdersLoaded(orders: orders, hasMore: hasMore, page: page));
        } else {
          final current = state as OrdersLoaded;
          emit(OrdersLoaded(
            orders: [...current.orders, ...orders],
            hasMore: hasMore,
            page: page,
          ));
        }
      } else {
        if (!event.refresh) {
          emit((state as OrdersLoaded).copyWith(isLoadingMore: false));
        } else {
          emit(OrderTrackError(response.error ?? 'Failed to load orders'));
        }
      }
    } catch (e) {
      if (!event.refresh) {
        emit((state as OrdersLoaded).copyWith(isLoadingMore: false));
      } else {
        emit(OrderTrackError(e.toString()));
      }
    }
  }

  Future<void> _onLoadMore(LoadMoreOrders event, Emitter<OrderTrackState> emit) async {
    if (state is! OrdersLoaded) return;
    final current = state as OrdersLoaded;
    if (current.isLoadingMore || !current.hasMore) return;
    add(const LoadOrders(refresh: false));
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

  Future<void> _onCancelOrder(CancelOrder event, Emitter<OrderTrackState> emit) async {
    try {
      final body = event.reason != null ? {'reason': event.reason} : <String, dynamic>{};
      final response = await _api.patch('/api/v1/orders/${event.orderId}/cancel', body: body);
      if (response.isSuccess) {
        add(LoadOrderDetail(event.orderId));
      } else {
        emit(OrderTrackError(response.error ?? 'Failed to cancel order'));
      }
    } catch (e) {
      emit(OrderTrackError(e.toString()));
    }
  }

  Future<void> _onConfirmPickup(ConfirmPickup event, Emitter<OrderTrackState> emit) async {
    try {
      final response = await _api.patch('/api/v1/orders/${event.orderId}/status');
      if (response.isSuccess) {
        add(LoadOrderDetail(event.orderId));
      } else {
        emit(OrderTrackError(response.error ?? 'Failed to confirm pickup'));
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
          discountAmount: current.order.discountAmount,
          couponCode: current.order.couponCode,
          currency: current.order.currency,
          estimatedReadyAt: event.estimatedReadyAt ?? current.order.estimatedReadyAt,
          storeId: current.order.storeId,
          storeName: current.order.storeName,
          storeAddress: current.order.storeAddress,
          storeLat: current.order.storeLat,
          storeLng: current.order.storeLng,
          offerId: current.order.offerId,
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
            discountAmount: o.discountAmount,
            couponCode: o.couponCode,
            currency: o.currency,
            estimatedReadyAt: event.estimatedReadyAt ?? o.estimatedReadyAt,
            storeId: o.storeId,
            storeName: o.storeName,
            storeAddress: o.storeAddress,
            storeLat: o.storeLat,
            storeLng: o.storeLng,
            offerId: o.offerId,
            offerTitle: o.offerTitle,
            offerImageUrl: o.offerImageUrl,
            createdAt: o.createdAt,
            statusHistory: o.statusHistory,
          );
        }
        return o;
      }).toList();
      emit(OrdersLoaded(orders: updated, hasMore: current.hasMore, page: current.page));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
