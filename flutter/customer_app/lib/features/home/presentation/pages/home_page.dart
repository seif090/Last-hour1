import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/offers_bloc.dart';
import '../widgets/offer_card.dart';
import '../widgets/category_chips.dart';
import '../../../../core/widgets/error_screen.dart';
import '../../../../core/widgets/infinite_scroll_list.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<OffersBloc>().add(const FetchOffers(refresh: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Last Hour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: _showSortSheet,
          ),
        ],
      ),
      body: BlocBuilder<OffersBloc, OffersState>(
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
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                          ),
                        )
                      : InfiniteScrollList(
                          itemCount: state.offers.length,
                          isLoading: state.isLoadingMore,
                          hasMore: state.hasMore,
                          onLoadMore: () => context.read<OffersBloc>().add(const LoadMoreOffers()),
                          itemBuilder: (index) => OfferCard(
                            offer: state.offers[index],
                            onTap: () => _navigateToDetail(state.offers[index].id),
                          ),
                        ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
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
}
