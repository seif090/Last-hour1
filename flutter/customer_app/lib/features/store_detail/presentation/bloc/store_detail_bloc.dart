import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lasthour_shared/models/store.dart';
import '../../../../services/api_client.dart';

abstract class StoreDetailEvent extends Equatable {
  const StoreDetailEvent();
  @override
  List<Object?> get props => [];
}

class LoadStoreDetail extends StoreDetailEvent {
  final String storeId;
  const LoadStoreDetail(this.storeId);
}

abstract class StoreDetailState extends Equatable {
  const StoreDetailState();
  @override
  List<Object?> get props => [];
}

class StoreDetailInitial extends StoreDetailState {}
class StoreDetailLoading extends StoreDetailState {}
class StoreDetailLoaded extends StoreDetailState {
  final Store store;
  final List<Map<String, dynamic>> menu;
  final List<Map<String, dynamic>> reviews;
  const StoreDetailLoaded({required this.store, required this.menu, this.reviews = const []});
  @override
  List<Object?> get props => [store, menu, reviews];
}
class StoreDetailError extends StoreDetailState {
  final String message;
  const StoreDetailError(this.message);
  @override
  List<Object?> get props => [message];
}

class StoreDetailBloc extends Bloc<StoreDetailEvent, StoreDetailState> {
  final ApiClient _api;

  StoreDetailBloc({required ApiClient api}) : _api = api, super(StoreDetailInitial()) {
    on<LoadStoreDetail>(_onLoad);
  }

  Future<void> _onLoad(LoadStoreDetail event, Emitter<StoreDetailState> emit) async {
    emit(StoreDetailLoading());
    try {
      final results = await Future.wait([
        _api.get('/api/v1/stores/${event.storeId}'),
        _api.get('/api/v1/stores/${event.storeId}/menu'),
        _api.get('/api/v1/reviews/store/${event.storeId}'),
      ]);
      final storeResp = results[0];
      final menuResp = results[1];
      final reviewResp = results[2];

      if (storeResp.isSuccess && storeResp.data != null && menuResp.isSuccess && menuResp.data != null) {
        final storeData = storeResp.data!['data'] as Map<String, dynamic>? ?? storeResp.data!;
        final menuData = menuResp.data!['data'] as List<dynamic>? ?? [];
        final reviewData = (reviewResp.data?['data'] as List<dynamic>?) ?? (reviewResp.data?['reviews'] as List<dynamic>?) ?? [];
        final store = Store.fromJson(storeData);
        final menu = menuData.cast<Map<String, dynamic>>();
        final reviews = reviewData.cast<Map<String, dynamic>>();
        emit(StoreDetailLoaded(store: store, menu: menu, reviews: reviews));
      } else {
        emit(StoreDetailError(storeResp.error ?? menuResp.error ?? 'Failed to load store'));
      }
    } catch (e) {
      emit(StoreDetailError(e.toString()));
    }
  }
}
