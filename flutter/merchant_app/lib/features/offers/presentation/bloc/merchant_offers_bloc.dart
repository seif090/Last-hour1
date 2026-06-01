import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lasthour_shared/models/offer.dart';
import '../../../services/api_client.dart';

abstract class MerchantOffersEvent extends Equatable {
  const MerchantOffersEvent();
  @override
  List<Object?> get props => [];
}

class LoadMerchantOffers extends MerchantOffersEvent {}
class CreateOffer extends MerchantOffersEvent {
  final Map<String, dynamic> data;
  const CreateOffer(this.data);
}
class UpdateStock extends MerchantOffersEvent {
  final String offerId;
  final int newStock;
  const UpdateStock(this.offerId, this.newStock);
}
class EndOffer extends MerchantOffersEvent {
  final String offerId;
  const EndOffer(this.offerId);
}
class DeleteOffer extends MerchantOffersEvent {
  final String offerId;
  const DeleteOffer(this.offerId);
}
class LoadProducts extends MerchantOffersEvent {}

abstract class MerchantOffersState extends Equatable {
  const MerchantOffersState();
  @override
  List<Object?> get props => [];
}

class MerchantOffersInitial extends MerchantOffersState {}
class MerchantOffersLoading extends MerchantOffersState {}
class MerchantOffersLoaded extends MerchantOffersState {
  final List<Offer> offers;
  final List<Map<String, dynamic>> products;
  const MerchantOffersLoaded({this.offers = const [], this.products = const []});
  @override
  List<Object?> get props => [offers, products];
}
class MerchantOffersError extends MerchantOffersState {
  final String message;
  const MerchantOffersError(this.message);
  @override
  List<Object?> get props => [message];
}
class OfferActionSuccess extends MerchantOffersState {
  final String message;
  const OfferActionSuccess(this.message);
  @override
  List<Object?> get props => [message];
}

class MerchantOffersBloc extends Bloc<MerchantOffersEvent, MerchantOffersState> {
  final ApiClient _api;

  MerchantOffersBloc({required ApiClient api}) : _api = api, super(MerchantOffersInitial()) {
    on<LoadMerchantOffers>(_onLoad);
    on<CreateOffer>(_onCreate);
    on<UpdateStock>(_onUpdateStock);
    on<EndOffer>(_onEnd);
    on<DeleteOffer>(_onDelete);
    on<LoadProducts>(_onLoadProducts);
  }

  Future<void> _onLoad(LoadMerchantOffers event, Emitter<MerchantOffersState> emit) async {
    emit(MerchantOffersLoading());
    try {
      final response = await _api.get('/api/v1/merchant/offers');
      if (response.isSuccess && response.data != null) {
        final offers = (response.data!['offers'] as List? ?? [])
            .map((j) => Offer.fromJson(j as Map<String, dynamic>))
            .toList();
        emit(MerchantOffersLoaded(offers: offers));
      } else {
        emit(MerchantOffersError(response.error ?? 'Failed to load offers'));
      }
    } catch (e) {
      emit(MerchantOffersError(e.toString()));
    }
  }

  Future<void> _onCreate(CreateOffer event, Emitter<MerchantOffersState> emit) async {
    emit(MerchantOffersLoading());
    try {
      final response = await _api.post('/api/v1/merchant/offers', body: event.data);
      if (response.isSuccess) {
        emit(const OfferActionSuccess('Offer created'));
        add(const LoadMerchantOffers());
      } else {
        emit(MerchantOffersError(response.error ?? 'Failed to create offer'));
      }
    } catch (e) {
      emit(MerchantOffersError(e.toString()));
    }
  }

  Future<void> _onUpdateStock(UpdateStock event, Emitter<MerchantOffersState> emit) async {
    try {
      final response = await _api.patch('/api/v1/merchant/offers/${event.offerId}/stock', body: {
        'stock': event.newStock,
      });
      if (response.isSuccess) {
        emit(const OfferActionSuccess('Stock updated'));
        add(const LoadMerchantOffers());
      } else {
        emit(MerchantOffersError(response.error ?? 'Failed to update stock'));
      }
    } catch (e) {
      emit(MerchantOffersError(e.toString()));
    }
  }

  Future<void> _onEnd(EndOffer event, Emitter<MerchantOffersState> emit) async {
    try {
      final response = await _api.patch('/api/v1/merchant/offers/${event.offerId}', body: {
        'end_now': true,
      });
      if (response.isSuccess) {
        emit(const OfferActionSuccess('Offer ended'));
        add(const LoadMerchantOffers());
      } else {
        emit(MerchantOffersError(response.error ?? 'Failed to end offer'));
      }
    } catch (e) {
      emit(MerchantOffersError(e.toString()));
    }
  }

  Future<void> _onDelete(DeleteOffer event, Emitter<MerchantOffersState> emit) async {
    try {
      final response = await _api.delete('/api/v1/merchant/offers/${event.offerId}');
      if (response.isSuccess) {
        emit(const OfferActionSuccess('Offer deleted'));
        add(const LoadMerchantOffers());
      } else {
        emit(MerchantOffersError(response.error ?? 'Failed to delete offer'));
      }
    } catch (e) {
      emit(MerchantOffersError(e.toString()));
    }
  }

  Future<void> _onLoadProducts(LoadProducts event, Emitter<MerchantOffersState> emit) async {
    try {
      final response = await _api.get('/api/v1/merchant/products');
      if (response.isSuccess && response.data != null) {
        final products = (response.data!['products'] as List? ?? []).cast<Map<String, dynamic>>();
        if (state is MerchantOffersLoaded) {
          emit((state as MerchantOffersLoaded).copyWith(products: products));
        } else {
          emit(MerchantOffersLoaded(products: products));
        }
      }
    } catch (_) {}
  }

  @override
  Future<void> close() => super.close();
}

extension _Copy on MerchantOffersLoaded {
  MerchantOffersLoaded copyWith({List<Offer>? offers, List<Map<String, dynamic>>? products}) {
    return MerchantOffersLoaded(
      offers: offers ?? this.offers,
      products: products ?? this.products,
    );
  }
}
