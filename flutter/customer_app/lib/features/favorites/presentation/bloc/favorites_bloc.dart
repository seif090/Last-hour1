import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../services/api_client.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoritesEvent {}
class AddFavorite extends FavoritesEvent {
  final String offerId;
  const AddFavorite(this.offerId);
}
class RemoveFavorite extends FavoritesEvent {
  final String offerId;
  const RemoveFavorite(this.offerId);
}
class CheckFavorite extends FavoritesEvent {
  final String offerId;
  const CheckFavorite(this.offerId);
}

abstract class FavoritesState extends Equatable {
  const FavoritesState();
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}
class FavoritesLoading extends FavoritesState {}
class FavoritesLoaded extends FavoritesState {
  final List<Map<String, dynamic>> favorites;
  final Map<String, bool> favoritedMap;
  const FavoritesLoaded({this.favorites = const [], this.favoritedMap = const {}});
  @override
  List<Object?> get props => [favorites, favoritedMap];
}
class FavoritesError extends FavoritesState {
  final String message;
  const FavoritesError(this.message);
  @override
  List<Object?> get props => [message];
}
class FavoriteCheckResult extends FavoritesState {
  final bool isFavorited;
  const FavoriteCheckResult(this.isFavorited);
}

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final ApiClient _api;

  FavoritesBloc({required ApiClient api}) : _api = api, super(FavoritesInitial()) {
    on<LoadFavorites>(_onLoad);
    on<AddFavorite>(_onAdd);
    on<RemoveFavorite>(_onRemove);
    on<CheckFavorite>(_onCheck);
  }

  Future<void> _onLoad(LoadFavorites event, Emitter<FavoritesState> emit) async {
    emit(FavoritesLoading());
    try {
      final response = await _api.get('/api/v1/favorites');
      if (response.isSuccess && response.data != null) {
        final list = response.data!['data'] as List<dynamic>? ?? [];
        final map = <String, bool>{};
        for (final item in list) {
          final offerId = (item as Map<String, dynamic>)['offer_id'] as String? ?? (item['offer'] as Map<String, dynamic>?)?['id'] as String? ?? '';
          if (offerId.isNotEmpty) map[offerId] = true;
        }
        emit(FavoritesLoaded(favorites: list.cast<Map<String, dynamic>>(), favoritedMap: map));
      } else {
        emit(FavoritesError(response.error ?? 'Failed to load favorites'));
      }
    } catch (e) {
      emit(FavoritesError(e.toString()));
    }
  }

  Future<void> _onAdd(AddFavorite event, Emitter<FavoritesState> emit) async {
    try {
      await _api.post('/api/v1/favorites/${event.offerId}');
      add(LoadFavorites());
    } catch (_) {}
  }

  Future<void> _onRemove(RemoveFavorite event, Emitter<FavoritesState> emit) async {
    try {
      await _api.delete('/api/v1/favorites/${event.offerId}');
      if (state is FavoritesLoaded) {
        final current = state as FavoritesLoaded;
        final newMap = Map<String, bool>.from(current.favoritedMap)..remove(event.offerId);
        emit(FavoritesLoaded(
          favorites: current.favorites.where((f) {
            final fid = f['offer_id'] as String? ?? f['offer']?['id'] as String? ?? '';
            return fid != event.offerId;
          }).toList(),
          favoritedMap: newMap,
        ));
      } else {
        add(LoadFavorites());
      }
    } catch (_) {}
  }

  Future<void> _onCheck(CheckFavorite event, Emitter<FavoritesState> emit) async {
    try {
      final response = await _api.get('/api/v1/favorites/check/${event.offerId}');
      if (response.isSuccess && response.data != null) {
        final favorited = response.data!['favorited'] as bool? ?? false;
        emit(FavoriteCheckResult(favorited));
      }
    } catch (_) {}
  }
}
