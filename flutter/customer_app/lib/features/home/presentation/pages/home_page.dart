import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/offers_bloc.dart';
import '../bloc/search_bloc.dart';
import '../widgets/offer_card.dart';
import '../widgets/category_chips.dart';
import '../../../../core/widgets/error_screen.dart';
import '../../../../core/widgets/infinite_scroll_list.dart';
import '../../../../services/api_client.dart';
import '../../../../injector.dart';
import '../../../../services/location_service.dart';
import '../../../favorites/presentation/bloc/favorites_bloc.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FavoritesBloc _favBloc;
  late final SearchBloc _searchBloc;
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    context.read<OffersBloc>().add(const FetchOffers(refresh: true));
    _favBloc = FavoritesBloc(api: sl<ApiClient>());
    _favBloc.add(LoadFavorites());
    _searchBloc = SearchBloc(api: sl<ApiClient>());
  }

  @override
  void dispose() {
    _favBloc.close();
    _searchBloc.close();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Last Hour'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchCtrl.clear();
                _searchBloc.add(ClearSearch());
              }
            }),
          ),
          if (!_isSearching) ...[
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: _showSortSheet,
            ),
            IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go('/profile'),
            ),
          ],
        ],
      ),
      body: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _favBloc),
          BlocProvider.value(value: _searchBloc),
        ],
        child: _isSearching ? _buildSearchView() : _buildOffersView(),
      ),
    );
  }

  Widget _buildSearchView() {
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search offers, stores...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
            ),
            onChanged: (q) {
              if (q.trim().isEmpty) {
                _searchBloc.add(ClearSearch());
                return;
              }
              final loc = sl<LocationService>().lastPosition;
              if (loc != null) {
                _searchBloc.add(SearchOffers(query: q, lat: loc.latitude, lng: loc.longitude));
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: BlocBuilder<SearchBloc, SearchState>(
            builder: (context, state) {
              if (state is SearchLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is SearchLoaded) {
                if (state.results.isEmpty) {
                  return Center(child: Text('No results for "${state.query}"', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
                }
                return InfiniteScrollList(
                  itemCount: state.results.length,
                  isLoading: state.isLoadingMore,
                  hasMore: state.hasMore,
                  onLoadMore: () => _searchBloc.add(LoadMoreSearch()),
                  itemBuilder: (i) => BlocBuilder<FavoritesBloc, FavoritesState>(
                    builder: (ctx, favState) {
                      final offer = state.results[i];
                      final isFav = favState is FavoritesLoaded && favState.favoritedMap[offer.id] == true;
                      return OfferCard(
                        offer: offer,
                        onTap: () => context.go('/offers/${offer.id}'),
                        onStoreTap: () => context.go('/stores/${offer.storeId}'),
                        isFavorited: isFav,
                        onFavoriteToggle: () {
                          if (isFav) {
                            _favBloc.add(RemoveFavorite(offer.id));
                          } else {
                            _favBloc.add(AddFavorite(offer.id));
                          }
                        },
                      );
                    },
                  ),
                );
              }
              if (state is SearchEmpty) {
                return Center(child: Text('No results for "${state.query}"', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)));
              }
              if (state is SearchError) {
                return ErrorScreen(message: state.message, onRetry: () {});
              }
              return Center(
                child: Text('Search for offers by name or store', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOffersView() {
    final theme = Theme.of(context);
    return BlocBuilder<OffersBloc, OffersState>(
      builder: (context, state) {
        if (state is OffersLoading && !(state is OffersLoaded)) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is OffersError) {
          return ErrorScreen(
            message: state.message,
            onRetry: () => context.read<OffersBloc>().add(const FetchOffers(refresh: true)),
          );
        }
        if (state is OffersLoaded) {
          return Column(
            children: [
              CategoryChips(
                selected: state.category,
                onSelected: (c) => context.read<OffersBloc>().add(CategoryFilterChanged(c)),
              ),
              Expanded(
                child: state.offers.isEmpty
                    ? Center(
                        child: Text(
                          'No offers nearby',
                          style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16),
                        ),
                      )
                    : InfiniteScrollList(
                        itemCount: state.offers.length,
                        isLoading: state.isLoadingMore,
                        hasMore: state.hasMore,
                        onLoadMore: () => context.read<OffersBloc>().add(LoadMoreOffers()),
                        itemBuilder: (index) => BlocBuilder<FavoritesBloc, FavoritesState>(
                          builder: (ctx, favState) {
                            final offer = state.offers[index];
                            final isFav = favState is FavoritesLoaded && favState.favoritedMap[offer.id] == true;
                            return OfferCard(
                              offer: offer,
                              onTap: () => _navigateToDetail(offer.id),
                              onStoreTap: () => _navigateToStore(offer.storeId),
                              isFavorited: isFav,
                              onFavoriteToggle: () {
                                if (isFav) {
                                  _favBloc.add(RemoveFavorite(offer.id));
                                } else {
                                  _favBloc.add(AddFavorite(offer.id));
                                }
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        }
        return const SizedBox();
      },
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Sort by', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.near_me),
              title: const Text('Nearest'),
              onTap: () {
                context.read<OffersBloc>().add(const SortChanged('distance'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_fire_department),
              title: const Text('Biggest discount'),
              onTap: () {
                context.read<OffersBloc>().add(const SortChanged('discount'));
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.av_timer),
              title: const Text('Ending soon'),
              onTap: () {
                context.read<OffersBloc>().add(const SortChanged('expiring'));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToDetail(String offerId) {
    context.go('/offers/$offerId');
  }

  void _navigateToStore(String storeId) {
    context.go('/stores/$storeId');
  }
}
