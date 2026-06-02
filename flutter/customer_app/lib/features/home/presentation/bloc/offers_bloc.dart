import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../services/api_client.dart';
import '../../../../services/location_service.dart';
import '../../../../services/websocket_service.dart';
import 'package:lasthour_shared/models/offer.dart';

abstract class OffersEvent extends Equatable {
  const OffersEvent();
  @override
  List<Object?> get props => [];
}

class FetchOffers extends OffersEvent {
  final bool refresh;
  const FetchOffers({this.refresh = false});
}
class LoadMoreOffers extends OffersEvent {}
class CategoryFilterChanged extends OffersEvent {
  final String category;
  const CategoryFilterChanged(this.category);
}
class LocationUpdated extends OffersEvent {
  final double lat;
  final double lng;
  const LocationUpdated(this.lat, this.lng);
}
class StockUpdateReceived extends OffersEvent {
  final String offerId;
  final int newStock;
  const StockUpdateReceived(this.offerId, this.newStock);
}
class OfferExpiredReceived extends OffersEvent {
  final String offerId;
  const OfferExpiredReceived(this.offerId);
}
class SortChanged extends OffersEvent {
  final String sortBy;
  const SortChanged(this.sortBy);
}

abstract class OffersState extends Equatable {
  const OffersState();
  @override
  List<Object?> get props => [];
}

class OffersInitial extends OffersState {}
class OffersLoading extends OffersState {}
class OffersLoaded extends OffersState {
  final List<Offer> offers;
  final bool hasMore;
  final bool isLoadingMore;
  final String category;
  final String sortBy;
  final Position? location;

  const OffersLoaded({
    this.offers = const [],
    this.hasMore = true,
    this.isLoadingMore = false,
    this.category = 'all',
    this.sortBy = 'distance',
    this.location,
  });

  OffersLoaded copyWith({
    List<Offer>? offers,
    bool? hasMore,
    bool? isLoadingMore,
    String? category,
    String? sortBy,
    Position? location,
  }) {
    return OffersLoaded(
      offers: offers ?? this.offers,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      category: category ?? this.category,
      sortBy: sortBy ?? this.sortBy,
      location: location ?? this.location,
    );
  }

  @override
  List<Object?> get props => [offers, hasMore, isLoadingMore, category, sortBy, location];
}

class OffersError extends OffersState {
  final String message;
  const OffersError(this.message);
  @override
  List<Object?> get props => [message];
}

class OffersBloc extends Bloc<OffersEvent, OffersState> {
  final ApiClient _api;
  final WebSocketService _ws;
  final LocationService _location;
  int _page = 1;
  static const _perPage = 20;
  StreamSubscription? _wsSubscription;

  OffersBloc({
    required ApiClient api,
    required WebSocketService ws,
    required LocationService location,
  })  : _api = api,
        _ws = ws,
        _location = location,
        super(OffersInitial()) {
    on<FetchOffers>(_onFetchOffers);
    on<LoadMoreOffers>(_onLoadMore);
    on<CategoryFilterChanged>(_onCategoryChanged);
    on<LocationUpdated>(_onLocationUpdated);
    on<StockUpdateReceived>(_onStockUpdate);
    on<OfferExpiredReceived>(_onOfferExpired);
    on<SortChanged>(_onSortChanged);

    _setupWebSocket();
  }

  void _setupWebSocket() {
    _ws.connect(room: 'offers');
    _wsSubscription = _ws.messages.listen((msg) {
      final event = msg['event'] as String?;
      final data = msg['data'] as Map<String, dynamic>? ?? {};

      if (event == 'stock:update') {
        add(StockUpdateReceived(data['offer_id'] as String, data['stock_remaining'] as int));
      } else if (event == 'offer:expired') {
        add(OfferExpiredReceived(data['offer_id'] as String));
      }
    });
  }

  Future<void> _onFetchOffers(FetchOffers event, Emitter<OffersState> emit) async {
    if (event.refresh) _page = 1;

    emit(state is OffersLoaded
        ? (state as OffersLoaded).copyWith(isLoadingMore: !event.refresh)
        : OffersLoading());

    try {
      Position? pos;
      try {
        pos = await _location.getCurrentPosition();
      } catch (_) {}

      final params = <String, dynamic>{
        'page': _page,
        'perPage': _perPage,
        if (state is OffersLoaded) ...{
          'category': (state as OffersLoaded).category,
          'sortBy': (state as OffersLoaded).sortBy,
        },
        if (pos != null) ...{
          'lat': pos.latitude,
          'lng': pos.longitude,
        },
      };

      final response = await _api.get('/api/v1/offers/nearby', queryParams: params);

      if (response.isSuccess && response.data != null) {
        final items = (response.data!['offers'] as List? ?? [])
            .map((j) => Offer.fromJson(j as Map<String, dynamic>))
            .toList();

        final totalPages = response.data!['totalPages'] as int? ?? 1;

        if (event.refresh || _page == 1) {
          emit(OffersLoaded(
            offers: items,
            hasMore: _page < totalPages,
            location: pos,
            category: (state is OffersLoaded) ? (state as OffersLoaded).category : 'all',
            sortBy: (state is OffersLoaded) ? (state as OffersLoaded).sortBy : 'distance',
          ));
        } else {
          final current = state as OffersLoaded;
          emit(current.copyWith(
            offers: [...current.offers, ...items],
            hasMore: _page < totalPages,
            isLoadingMore: false,
            location: pos,
          ));
        }
      } else {
        emit(OffersError(response.error ?? 'Failed to load offers'));
      }
    } catch (e) {
      emit(OffersError(e.toString()));
    }
  }

  Future<void> _onLoadMore(LoadMoreOffers event, Emitter<OffersState> emit) async {
    if (state is! OffersLoaded) return;
    final current = state as OffersLoaded;
    if (current.isLoadingMore || !current.hasMore) return;

    _page++;
    emit(current.copyWith(isLoadingMore: true));
    add(const FetchOffers());
  }

  void _onCategoryChanged(CategoryFilterChanged event, Emitter<OffersState> emit) {
    if (state is OffersLoaded) {
      emit((state as OffersLoaded).copyWith(category: event.category));
    }
    _page = 1;
    add(const FetchOffers(refresh: true));
  }

  void _onLocationUpdated(LocationUpdated event, Emitter<OffersState> emit) {
    if (state is OffersLoaded) {
      emit((state as OffersLoaded).copyWith(
        location: Position(
          latitude: event.lat,
          longitude: event.lng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      ));
    }
  }

  void _onStockUpdate(StockUpdateReceived event, Emitter<OffersState> emit) {
    if (state is OffersLoaded) {
      final current = state as OffersLoaded;
      final updated = current.offers.map((o) {
        if (o.id == event.offerId) {
          return Offer(
            id: o.id,
            title: o.title,
            discountedPrice: o.discountedPrice,
            originalPrice: o.originalPrice,
            stockRemaining: event.newStock,
            stockInitial: o.stockInitial,
            endTime: o.endTime,
            maxPerCustomer: o.maxPerCustomer,
            imageUrl: o.imageUrl,
            storeId: o.storeId,
            storeName: o.storeName,
            storeSlug: o.storeSlug,
            cuisineType: o.cuisineType,
            ratingAvg: o.ratingAvg,
            ratingCount: o.ratingCount,
            distanceM: o.distanceM,
            productName: o.productName,
            category: o.category,
            lat: o.lat,
            lng: o.lng,
          );
        }
        return o;
      }).toList();
      emit(current.copyWith(offers: updated));
    }
  }

  void _onOfferExpired(OfferExpiredReceived event, Emitter<OffersState> emit) {
    if (state is OffersLoaded) {
      final current = state as OffersLoaded;
      emit(current.copyWith(
        offers: current.offers.where((o) => o.id != event.offerId).toList(),
      ));
    }
  }

  void _onSortChanged(SortChanged event, Emitter<OffersState> emit) {
    if (state is OffersLoaded) {
      emit((state as OffersLoaded).copyWith(sortBy: event.sortBy));
    }
    _page = 1;
    add(const FetchOffers(refresh: true));
  }

  @override
  Future<void> close() {
    _wsSubscription?.cancel();
    return super.close();
  }
}
