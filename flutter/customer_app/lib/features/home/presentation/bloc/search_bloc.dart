import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:lasthour_shared/models/offer.dart';
import '../../../../services/api_client.dart';

abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class SearchOffers extends SearchEvent {
  final String query;
  final double lat;
  final double lng;
  const SearchOffers({required this.query, required this.lat, required this.lng});
}
class ClearSearch extends SearchEvent {}

abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}
class SearchLoaded extends SearchState {
  final List<Offer> results;
  final String query;
  const SearchLoaded({this.results = const [], this.query = ''});
  @override
  List<Object?> get props => [results, query];
}
class SearchEmpty extends SearchState {
  final String query;
  const SearchEmpty(this.query);
  @override
  List<Object?> get props => [query];
}
class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ApiClient _api;

  SearchBloc({required ApiClient api}) : _api = api, super(SearchInitial()) {
    on<SearchOffers>(_onSearch);
    on<ClearSearch>((_, emit) => emit(SearchInitial()));
  }

  Future<void> _onSearch(SearchOffers event, Emitter<SearchState> emit) async {
    if (event.query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }
    emit(SearchLoading());
    try {
      final response = await _api.get('/api/v1/offers/search', queryParams: {
        'q': event.query.trim(),
        'lat': event.lat.toString(),
        'lng': event.lng.toString(),
        'radius': '20000',
        'limit': '50',
      });
      if (response.isSuccess && response.data != null) {
        final list = response.data!['offers'] as List<dynamic>? ?? [];
        if (list.isEmpty) {
          emit(SearchEmpty(event.query));
        } else {
          final offers = list.map((j) => Offer.fromJson(j as Map<String, dynamic>)).toList();
          emit(SearchLoaded(results: offers, query: event.query));
        }
      } else {
        emit(SearchError(response.error ?? 'Search failed'));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }
}
