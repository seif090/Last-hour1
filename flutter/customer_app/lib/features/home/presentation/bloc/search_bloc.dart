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
  final bool refresh;
  const SearchOffers({required this.query, required this.lat, required this.lng, this.refresh = true});
}
class LoadMoreSearch extends SearchEvent {}
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
  final bool hasMore;
  final bool isLoadingMore;
  final int page;
  const SearchLoaded({
    this.results = const [],
    this.query = '',
    this.hasMore = false,
    this.isLoadingMore = false,
    this.page = 1,
  });

  SearchLoaded copyWith({
    List<Offer>? results,
    String? query,
    bool? hasMore,
    bool? isLoadingMore,
    int? page,
  }) {
    return SearchLoaded(
      results: results ?? this.results,
      query: query ?? this.query,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      page: page ?? this.page,
    );
  }

  @override
  List<Object?> get props => [results, query, hasMore, isLoadingMore, page];
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
  String? _currentQuery;
  double? _currentLat;
  double? _currentLng;

  SearchBloc({required ApiClient api}) : _api = api, super(SearchInitial()) {
    on<SearchOffers>(_onSearch);
    on<LoadMoreSearch>(_onLoadMore);
    on<ClearSearch>((_, emit) {
      _currentQuery = null;
      _currentLat = null;
      _currentLng = null;
      emit(SearchInitial());
    });
  }

  Future<void> _onSearch(SearchOffers event, Emitter<SearchState> emit) async {
    if (event.query.trim().isEmpty) {
      emit(SearchInitial());
      return;
    }

    _currentQuery = event.query.trim();
    _currentLat = event.lat;
    _currentLng = event.lng;

    if (event.refresh) {
      emit(SearchLoading());
    } else if (state is SearchLoaded) {
      emit((state as SearchLoaded).copyWith(isLoadingMore: true));
    }

    final page = event.refresh ? 1 : (state is SearchLoaded ? (state as SearchLoaded).page + 1 : 1);

    try {
      final response = await _api.get('/api/v1/offers/search', queryParams: {
        'q': _currentQuery!,
        'lat': _currentLat.toString(),
        'lng': _currentLng.toString(),
        'radius': '20000',
        'page': page.toString(),
        'limit': '20',
      });
      if (response.isSuccess && response.data != null) {
        final list = response.data!['offers'] as List<dynamic>? ?? [];
        if (list.isEmpty && event.refresh) {
          emit(SearchEmpty(_currentQuery!));
          return;
        }
        final offers = list.map((j) => Offer.fromJson(j as Map<String, dynamic>)).toList();
        final meta = response.data!['meta'] as Map<String, dynamic>? ?? {};
        final hasMore = meta['hasMore'] as bool? ?? false;

        if (event.refresh) {
          emit(SearchLoaded(results: offers, query: _currentQuery!, hasMore: hasMore, page: page));
        } else {
          final current = state as SearchLoaded;
          emit(SearchLoaded(
            results: [...current.results, ...offers],
            query: _currentQuery!,
            hasMore: hasMore,
            page: page,
          ));
        }
      } else {
        if (!event.refresh) {
          emit((state as SearchLoaded).copyWith(isLoadingMore: false));
        } else {
          emit(SearchError(response.error ?? 'Search failed'));
        }
      }
    } catch (e) {
      if (!event.refresh) {
        emit((state as SearchLoaded).copyWith(isLoadingMore: false));
      } else {
        emit(SearchError(e.toString()));
      }
    }
  }

  Future<void> _onLoadMore(LoadMoreSearch event, Emitter<SearchState> emit) async {
    if (state is! SearchLoaded) return;
    final current = state as SearchLoaded;
    if (current.isLoadingMore || !current.hasMore) return;
    add(SearchOffers(query: current.query, lat: _currentLat!, lng: _currentLng!, refresh: false));
  }
}
