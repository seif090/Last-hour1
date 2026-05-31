import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../services/api_client.dart';
import '../../../services/location_service.dart';
import '../../../services/websocket_service.dart';

// ─── Events ─────────────────────────────────────────────────────
abstract class OffersEvent extends Equatable {
  const OffersEvent();
  @override
  List<Object?> get props => [];
}

class FetchNearbyOffers extends OffersEvent {
  final double lat;
  final double lng;
  final int radius;
  final String? category;

  const FetchNearbyOffers({
    required this.lat,
    required this.lng,
    this.radius = 5000,
    this.category,
  });

  @override
  List<Object?> get props => [lat, lng, radius, category];
}

class RefreshOffers extends OffersEvent {}

class LoadMoreOffers extends OffersEvent {}

class StockUpdated extends OffersEvent {
  final String offerId;
  final int remaining;

  const StockUpdated(this.offerId, this.remaining);

  @override
  List<Object?> get props => [offerId, remaining];
}

class OfferRemoved extends OffersEvent {
  final String offerId;
  const OfferRemoved(this.offerId);
}

class SelectCategory extends OffersEvent {
  final String? category;
  const SelectCategory(this.category);
}

// ─── State ──────────────────────────────────────────────────────
abstract class OffersState extends Equatable {
  const OffersState();
  @override
  List<Object?> get props => [];
}

class OffersInitial extends OffersState {}

class OffersLoading extends OffersState {}

class OffersLoaded extends OffersState {
  final List<OfferCard> offers;
  final bool hasMore;
  final int currentPage;
  final String? selectedCategory;
  final int totalCount;

  const OffersLoaded({
    required this.offers,
    this.hasMore = false,
    this.currentPage = 1,
    this.selectedCategory,
    this.totalCount = 0,
  });

  OffersLoaded copyWith({
    List<OfferCard>? offers,
    bool? hasMore,
    int? currentPage,
    String? selectedCategory,
    int? totalCount,
  }) {
    return OffersLoaded(
      offers: offers ?? this.offers,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props =>
      [offers, hasMore, currentPage, selectedCategory, totalCount];
}

class OffersError extends OffersState {
  final String message;
  const OffersError(this.message);
}

// ─── Card Model ─────────────────────────────────────────────────
class OfferCard extends Equatable {
  final String id;
  final String title;
  final double discountedPrice;
  final double originalPrice;
  final int stockRemaining;
  final int stockInitial;
  final DateTime endTime;
  final String imageUrl;
  final String storeName;
  final double distanceM;
  final String category;

  const OfferCard({
    required this.id,
    required this.title,
    required this.discountedPrice,
    required this.originalPrice,
    required this.stockRemaining,
    required this.stockInitial,
    required this.endTime,
    required this.imageUrl,
    required this.storeName,
    required this.distanceM,
    required this.category,
  });

  bool get isLowStock => stockRemaining <= stockInitial * 0.1;
  double get discountPercent =>
      ((originalPrice - discountedPrice) / originalPrice * 100);

  @override
  List<Object?> get props => [id, stockRemaining];
}

// ─── BLoC ───────────────────────────────────────────────────────
class OffersBloc extends Bloc<OffersEvent, OffersState> {
  final ApiClient _api;
  final WebSocketService _ws;
  final LocationService _location;
  StreamSubscription? _wsSubscription;

  double _currentLat = 30.0444;
  double _currentLng = 31.2357;
  String? _currentCategory;

  OffersBloc({
    required ApiClient api,
    required WebSocketService ws,
    required LocationService location,
  })  : _api = api,
        _ws = ws,
        _location = location,
        super(OffersInitial()) {
    on<FetchNearbyOffers>(_onFetchNearby);
    on<RefreshOffers>(_onRefresh);
    on<LoadMoreOffers>(_onLoadMore);
    on<StockUpdated>(_onStockUpdated);
    on<OfferRemoved>(_onOfferRemoved);
    on<SelectCategory>(_onSelectCategory);

    _wsSubscription = _ws.offerFeed.listen((message) {
      final event = message['event'] as String?;
      if (event == 'stock:update') {
        add(StockUpdated(
          message['offer_id'] as String,
          message['stock_remaining'] as int,
        ));
      } else if (event == 'offer:expired' || event == 'offer:sold_out') {
        add(OfferRemoved(message['offer_id'] as String));
      }
    });
  }

  Future<void> _onFetchNearby(
      FetchNearbyOffers event, Emitter<OffersState> emit) async {
    _currentLat = event.lat;
    _currentLng = event.lng;
    _currentCategory = event.category;

    emit(OffersLoading());

    try {
      final response = await _api.get('/api/v1/offers/nearby', query: {
        'lat': _currentLat.toString(),
        'lng': _currentLng.toString(),
        'radius': event.radius.toString(),
        if (_currentCategory != null) 'category': _currentCategory,
      });

      if (response.isSuccess && response.data != null) {
        final offersList = (response.data!['offers'] as List)
            .map((j) => OfferCard(
                  id: j['id'],
                  title: j['title'],
                  discountedPrice: (j['discounted_price'] as num).toDouble(),
                  originalPrice: (j['original_price'] as num).toDouble(),
                  stockRemaining: j['stock_remaining'] as int,
                  stockInitial: j['stock_initial'] as int,
                  endTime: DateTime.parse(j['end_time'] as String),
                  imageUrl: j['image_url'] ?? '',
                  storeName: j['store']['name'],
                  distanceM: (j['store']['distance_m'] as num).toDouble(),
                  category: j['product']['category'],
                ))
            .toList();

        final meta = response.data!['meta'] as Map<String, dynamic>;

        emit(OffersLoaded(
          offers: offersList,
          hasMore: meta['has_more'] as bool,
          totalCount: meta['total'] as int,
          selectedCategory: _currentCategory,
        ));
      } else {
        emit(OffersError(response.error ?? 'Failed to load offers'));
      }
    } catch (e) {
      emit(OffersError(e.toString()));
    }
  }

  Future<void> _onRefresh(RefreshOffers event, Emitter<OffersState> emit) async {
    try {
      final pos = await _location.getCurrentPosition();
      add(FetchNearbyOffers(
        lat: pos.latitude,
        lng: pos.longitude,
        category: _currentCategory,
      ));
    } catch (_) {
      add(FetchNearbyOffers(
        lat: _currentLat,
        lng: _currentLng,
        category: _currentCategory,
      ));
    }
  }

  Future<void> _onLoadMore(
      LoadMoreOffers event, Emitter<OffersState> emit) async {
    if (state is! OffersLoaded || !(state as OffersLoaded).hasMore) return;

    final current = state as OffersLoaded;
    final nextPage = current.currentPage + 1;

    try {
      final response = await _api.get('/api/v1/offers/nearby', query: {
        'lat': _currentLat.toString(),
        'lng': _currentLng.toString(),
        'page': nextPage.toString(),
      });

      if (response.isSuccess && response.data != null) {
        final newOffers = (response.data!['offers'] as List)
            .map((j) => OfferCard(
                  id: j['id'],
                  title: j['title'],
                  discountedPrice: (j['discounted_price'] as num).toDouble(),
                  originalPrice: (j['original_price'] as num).toDouble(),
                  stockRemaining: j['stock_remaining'] as int,
                  stockInitial: j['stock_initial'] as int,
                  endTime: DateTime.parse(j['end_time'] as String),
                  imageUrl: j['image_url'] ?? '',
                  storeName: j['store']['name'],
                  distanceM: (j['store']['distance_m'] as num).toDouble(),
                  category: j['product']['category'],
                ))
            .toList();

        emit(current.copyWith(
          offers: [...current.offers, ...newOffers],
          currentPage: nextPage,
          hasMore: response.data!['meta']['has_more'] as bool,
        ));
      }
    } catch (_) {}
  }

  void _onStockUpdated(StockUpdated event, Emitter<OffersState> emit) {
    if (state is OffersLoaded) {
      final current = state as OffersLoaded;
      final updated = current.offers.map((offer) {
        if (offer.id == event.offerId) {
          return OfferCard(
            id: offer.id,
            title: offer.title,
            discountedPrice: offer.discountedPrice,
            originalPrice: offer.originalPrice,
            stockRemaining: event.remaining,
            stockInitial: offer.stockInitial,
            endTime: offer.endTime,
            imageUrl: offer.imageUrl,
            storeName: offer.storeName,
            distanceM: offer.distanceM,
            category: offer.category,
          );
        }
        return offer;
      }).toList();

      emit(current.copyWith(offers: updated));
    }
  }

  void _onOfferRemoved(OfferRemoved event, Emitter<OffersState> emit) {
    if (state is OffersLoaded) {
      final current = state as OffersLoaded;
      emit(current.copyWith(
        offers: current.offers.where((o) => o.id != event.offerId).toList(),
      ));
    }
  }

  void _onSelectCategory(SelectCategory event, Emitter<OffersState> emit) {
    _currentCategory = event.category;
    add(FetchNearbyOffers(
      lat: _currentLat,
      lng: _currentLng,
      category: event.category,
    ));
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
