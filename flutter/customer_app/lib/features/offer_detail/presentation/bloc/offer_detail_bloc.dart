import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lasthour_shared/models/offer.dart';
import '../../../../services/api_client.dart';
import '../../../../services/websocket_service.dart';

abstract class OfferDetailEvent extends Equatable {
  const OfferDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadOfferDetail extends OfferDetailEvent {
  final String offerId;
  const LoadOfferDetail(this.offerId);
}
class UpdateQuantity extends OfferDetailEvent {
  final int quantity;
  const UpdateQuantity(this.quantity);
}
class PlaceOrder extends OfferDetailEvent {
  final int quantity;
  final String? couponCode;
  const PlaceOrder(this.quantity, {this.couponCode});
}
class StockUpdated extends OfferDetailEvent {
  final int newStock;
  const StockUpdated(this.newStock);
}

abstract class OfferDetailState extends Equatable {
  const OfferDetailState();
  @override
  List<Object?> get props => [];
}

class OfferDetailInitial extends OfferDetailState {}
class OfferDetailLoading extends OfferDetailState {}
class OfferDetailLoaded extends OfferDetailState {
  final Offer offer;
  final int quantity;
  final bool isPlacingOrder;
  final String? orderId;

  const OfferDetailLoaded({
    required this.offer,
    this.quantity = 1,
    this.isPlacingOrder = false,
    this.orderId,
  });

  OfferDetailLoaded copyWith({Offer? offer, int? quantity, bool? isPlacingOrder, String? orderId}) {
    return OfferDetailLoaded(
      offer: offer ?? this.offer,
      quantity: quantity ?? this.quantity,
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      orderId: orderId ?? this.orderId,
    );
  }

  @override
  List<Object?> get props => [offer, quantity, isPlacingOrder, orderId];
}

class OfferDetailError extends OfferDetailState {
  final String message;
  const OfferDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class OrderPlaced extends OfferDetailState {
  final String orderId;
  final String message;
  const OrderPlaced({required this.orderId, this.message = 'Order placed successfully!'});
  @override
  List<Object?> get props => [orderId, message];
}

class OfferDetailBloc extends Bloc<OfferDetailEvent, OfferDetailState> {
  final ApiClient _api;
  final WebSocketService _ws;
  StreamSubscription? _wsSub;

  OfferDetailBloc({required ApiClient api, required WebSocketService ws})
      : _api = api,
        _ws = ws,
        super(OfferDetailInitial()) {
    on<LoadOfferDetail>(_onLoad);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<PlaceOrder>(_onPlaceOrder);
    on<StockUpdated>(_onStockUpdated);

    _wsSub = _ws.onEvent('stock:update').listen((msg) {
      final data = msg['data'] as Map<String, dynamic>;
      if (state is OfferDetailLoaded) {
        final offerId = (state as OfferDetailLoaded).offer.id;
        if (data['offer_id'] == offerId) {
          add(StockUpdated(data['stock_remaining'] as int));
        }
      }
    });
  }

  Future<void> _onLoad(LoadOfferDetail event, Emitter<OfferDetailState> emit) async {
    emit(OfferDetailLoading());
    try {
      final response = await _api.get('/api/v1/offers/${event.offerId}');
      if (response.isSuccess && response.data != null) {
        final offer = Offer.fromJson(response.data!['offer'] as Map<String, dynamic>? ?? response.data!);
        emit(OfferDetailLoaded(offer: offer));
      } else {
        emit(OfferDetailError(response.error ?? 'Offer not found'));
      }
    } catch (e) {
      emit(OfferDetailError(e.toString()));
    }
  }

  void _onUpdateQuantity(UpdateQuantity event, Emitter<OfferDetailState> emit) {
    if (state is OfferDetailLoaded) {
      emit((state as OfferDetailLoaded).copyWith(quantity: event.quantity));
    }
  }

  Future<void> _onPlaceOrder(PlaceOrder event, Emitter<OfferDetailState> emit) async {
    if (state is! OfferDetailLoaded) return;
    final current = state as OfferDetailLoaded;

    emit(current.copyWith(isPlacingOrder: true));

    try {
      final response = await _api.post('/api/v1/orders', body: {
        'offer_id': current.offer.id,
        'quantity': event.quantity,
        if (event.couponCode != null && event.couponCode!.isNotEmpty)
          'coupon_code': event.couponCode,
      });

      if (response.isSuccess && response.data != null) {
        final orderId = response.data!['order_id'] ?? response.data!['id'];
        emit(OrderPlaced(orderId: orderId as String));
      } else {
        emit(current.copyWith(isPlacingOrder: false));
        emit(OfferDetailError(response.error ?? 'Order failed'));
        emit(current.copyWith(isPlacingOrder: false));
      }
    } catch (e) {
      emit(current.copyWith(isPlacingOrder: false));
      emit(OfferDetailError(e.toString()));
    }
  }

  void _onStockUpdated(StockUpdated event, Emitter<OfferDetailState> emit) {
    if (state is OfferDetailLoaded) {
      final current = state as OfferDetailLoaded;
      emit(current.copyWith(
        offer: Offer(
          id: current.offer.id,
          title: current.offer.title,
          discountedPrice: current.offer.discountedPrice,
          originalPrice: current.offer.originalPrice,
          stockRemaining: event.newStock,
          stockInitial: current.offer.stockInitial,
          endTime: current.offer.endTime,
          maxPerCustomer: current.offer.maxPerCustomer,
          imageUrl: current.offer.imageUrl,
          storeId: current.offer.storeId,
          storeName: current.offer.storeName,
          storeSlug: current.offer.storeSlug,
          cuisineType: current.offer.cuisineType,
          ratingAvg: current.offer.ratingAvg,
          ratingCount: current.offer.ratingCount,
          distanceM: current.offer.distanceM,
          productName: current.offer.productName,
          category: current.offer.category,
          lat: current.offer.lat,
          lng: current.offer.lng,
        ),
      ));
    }
  }

  @override
  Future<void> close() {
    _wsSub?.cancel();
    return super.close();
  }
}
