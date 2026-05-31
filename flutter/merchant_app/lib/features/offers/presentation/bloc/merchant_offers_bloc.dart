import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../services/api_client.dart';

// ─── Events ─────────────────────────────────────────────────────
abstract class MerchantOffersEvent extends Equatable {
  const MerchantOffersEvent();
  @override
  List<Object?> get props => [];
}

class LoadMerchantOffers extends MerchantOffersEvent {
  final String? status;
  const LoadMerchantOffers({this.status});
}

class CreateOffer extends MerchantOffersEvent {
  final CreateOfferData data;
  const CreateOffer(this.data);
}

class UpdateStock extends MerchantOffersEvent {
  final String offerId;
  final int stockRemaining;
  const UpdateStock(this.offerId, this.stockRemaining);
}

class PauseOffer extends MerchantOffersEvent {
  final String offerId;
  const PauseOffer(this.offerId);
}

class ResumeOffer extends MerchantOffersEvent {
  final String offerId;
  const ResumeOffer(this.offerId);
}

class LoadProducts extends MerchantOffersEvent {}

// ─── States ─────────────────────────────────────────────────────
abstract class MerchantOffersState extends Equatable {
  const MerchantOffersState();
  @override
  List<Object?> get props => [];
}

class MerchantOffersInitial extends MerchantOffersState {}

class MerchantOffersLoading extends MerchantOffersState {}

class MerchantOffersLoaded extends MerchantOffersState {
  final List<OfferItem> offers;
  final List<ProductItem> products;
  final int activeCount;
  final int soldOutCount;

  const MerchantOffersLoaded({
    required this.offers,
    required this.products,
    required this.activeCount,
    required this.soldOutCount,
  });

  MerchantOffersLoaded copyWith({
    List<OfferItem>? offers,
    List<ProductItem>? products,
    int? activeCount,
    int? soldOutCount,
  }) {
    return MerchantOffersLoaded(
      offers: offers ?? this.offers,
      products: products ?? this.products,
      activeCount: activeCount ?? this.activeCount,
      soldOutCount: soldOutCount ?? this.soldOutCount,
    );
  }

  @override
  List<Object?> get props => [offers, products, activeCount, soldOutCount];
}

class MerchantOffersError extends MerchantOffersState {
  final String message;
  const MerchantOffersError(this.message);
}

class OfferCreated extends MerchantOffersState {
  final String offerId;
  const OfferCreated(this.offerId);
}

class StockUpdated extends MerchantOffersState {
  final String offerId;
  final int newRemaining;
  const StockUpdated(this.offerId, this.newRemaining);
}

// ─── Data Models ───────────────────────────────────────────────
class OfferItem extends Equatable {
  final String id;
  final String title;
  final double originalPrice;
  final double discountedPrice;
  final int stockInitial;
  final int stockRemaining;
  final String status;
  final String productName;
  final DateTime endTime;
  final int version;

  const OfferItem({
    required this.id,
    required this.title,
    required this.originalPrice,
    required this.discountedPrice,
    required this.stockInitial,
    required this.stockRemaining,
    required this.status,
    required this.productName,
    required this.endTime,
    required this.version,
  });

  int get soldCount => stockInitial - stockRemaining;
  double get sellThroughRate => stockInitial > 0
      ? (stockInitial - stockRemaining) / stockInitial * 100
      : 0;

  @override
  List<Object?> get props => [id, stockRemaining, status, version];
}

class ProductItem extends Equatable {
  final String id;
  final String name;
  final String category;
  final double originalPrice;
  final String unit;

  const ProductItem({
    required this.id,
    required this.name,
    required this.category,
    required this.originalPrice,
    required this.unit,
  });

  @override
  List<Object?> get props => [id];
}

class CreateOfferData {
  final String productId;
  final String title;
  final String? description;
  final double discountedPrice;
  final double originalPrice;
  final int stockInitial;
  final int maxPerCustomer;
  final DateTime startTime;
  final DateTime endTime;
  final String? imageUrl;
  final List<String>? tags;

  const CreateOfferData({
    required this.productId,
    required this.title,
    this.description,
    required this.discountedPrice,
    required this.originalPrice,
    required this.stockInitial,
    this.maxPerCustomer = 5,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
    this.tags,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'title': title,
    'description': description,
    'discounted_price': discountedPrice,
    'original_price': originalPrice,
    'stock_initial': stockInitial,
    'max_per_customer': maxPerCustomer,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'image_url': imageUrl,
    'tags': tags,
  };
}

// ─── BLoC ───────────────────────────────────────────────────────
class MerchantOffersBloc extends Bloc<MerchantOffersEvent, MerchantOffersState> {
  final ApiClient _api;

  MerchantOffersBloc({required ApiClient api})
      : _api = api,
        super(MerchantOffersInitial()) {
    on<LoadMerchantOffers>(_onLoad);
    on<CreateOffer>(_onCreate);
    on<UpdateStock>(_onUpdateStock);
    on<PauseOffer>(_onPause);
    on<ResumeOffer>(_onResume);
    on<LoadProducts>(_onLoadProducts);
  }

  Future<void> _onLoad(LoadMerchantOffers event, Emitter<MerchantOffersState> emit) async {
    emit(MerchantOffersLoading());

    try {
      final offersRes = await _api.get('/api/v1/merchant/offers', query: {
        if (event.status != null) 'status': event.status,
      });

      final productsRes = await _api.get('/api/v1/merchant/products');

      if (offersRes.isSuccess && productsRes.isSuccess) {
        final offers = ((offersRes.data?['offers'] ?? offersRes.data) as List)
            .map((j) => OfferItem(
                  id: j['id'],
                  title: j['title'],
                  originalPrice: (j['original_price'] as num).toDouble(),
                  discountedPrice: (j['discounted_price'] as num).toDouble(),
                  stockInitial: j['stock_initial'] as int,
                  stockRemaining: j['stock_remaining'] as int,
                  status: j['status'],
                  productName: j['product']?['name'] ?? j['product_name'] ?? '',
                  endTime: DateTime.parse(j['end_time']),
                  version: j['version'] as int? ?? 1,
                ))
            .toList();

        final products = (productsRes.data as List)
            .map((j) => ProductItem(
                  id: j['id'],
                  name: j['name'],
                  category: j['category'],
                  originalPrice: (j['original_price'] as num).toDouble(),
                  unit: j['unit'] ?? 'piece',
                ))
            .toList();

        emit(MerchantOffersLoaded(
          offers: offers,
          products: products,
          activeCount: offers.where((o) => o.status == 'active').length,
          soldOutCount: offers.where((o) => o.status == 'sold_out').length,
        ));
      } else {
        emit(MerchantOffersError(
          offersRes.error ?? productsRes.error ?? 'Failed to load',
        ));
      }
    } catch (e) {
      emit(MerchantOffersError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateOffer event, Emitter<MerchantOffersState> emit) async {
    try {
      final response = await _api.post('/api/v1/merchant/offers', body: event.data.toJson());

      if (response.isSuccess) {
        // Refresh list after creation
        add(const LoadMerchantOffers());
        emit(OfferCreated(response.data?['id'] as String));
      } else {
        emit(MerchantOffersError(response.error ?? 'Failed to create offer'));
      }
    } catch (e) {
      emit(MerchantOffersError(e.toString()));
    }
  }

  Future<void> _onUpdateStock(UpdateStock event, Emitter<MerchantOffersState> emit) async {
    try {
      final response = await _api.patch(
        '/api/v1/merchant/offers/${event.offerId}/stock',
        body: {'stock_remaining': event.stockRemaining},
      );

      if (response.isSuccess) {
        add(const LoadMerchantOffers());
        emit(StockUpdated(event.offerId, event.stockRemaining));
      }
    } catch (_) {}
  }

  Future<void> _onPause(PauseOffer event, Emitter<MerchantOffersState> emit) async {
    try {
      await _api.patch('/api/v1/merchant/offers/${event.offerId}', body: {
        'status': 'paused',
      });
      add(const LoadMerchantOffers());
    } catch (_) {}
  }

  Future<void> _onResume(ResumeOffer event, Emitter<MerchantOffersState> emit) async {
    try {
      await _api.patch('/api/v1/merchant/offers/${event.offerId}', body: {
        'status': 'active',
      });
      add(const LoadMerchantOffers());
    } catch (_) {}
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<MerchantOffersState> emit) async {
    try {
      final response = await _api.get('/api/v1/merchant/products');
      if (response.isSuccess && state is MerchantOffersLoaded) {
        final current = state as MerchantOffersLoaded;
        final products = (response.data as List)
            .map((j) => ProductItem(
                  id: j['id'],
                  name: j['name'],
                  category: j['category'],
                  originalPrice: (j['original_price'] as num).toDouble(),
                  unit: j['unit'] ?? 'piece',
                ))
            .toList();
        emit(current.copyWith(products: products));
      }
    } catch (_) {}
  }
}
