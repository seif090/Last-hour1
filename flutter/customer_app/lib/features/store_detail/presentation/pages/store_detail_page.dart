import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lasthour_shared/models/store.dart';
import '../bloc/store_detail_bloc.dart';
import '../widgets/menu_item_card.dart';
import '../../../../core/widgets/error_screen.dart';
import '../../../../core/widgets/star_rating.dart';
import '../../../../services/api_client.dart';
import '../../../../injector.dart';

class StoreDetailPage extends StatefulWidget {
  final String storeId;
  const StoreDetailPage({super.key, required this.storeId});

  @override
  State<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends State<StoreDetailPage> {
  late final StoreDetailBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = StoreDetailBloc(api: sl<ApiClient>());
    _bloc.add(LoadStoreDetail(widget.storeId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<StoreDetailBloc, StoreDetailState>(
        builder: (context, state) {
          if (state is StoreDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is StoreDetailError) {
            return ErrorScreen(
              message: state.message,
              onRetry: () => _bloc.add(LoadStoreDetail(widget.storeId)),
            );
          }
          if (state is StoreDetailLoaded) {
            return _buildContent(state);
          }
          return const SizedBox();
        },
      ),
      ),
    );
  }

  Widget _buildContent(StoreDetailLoaded state) {
    final theme = Theme.of(context);
    final store = state.store;
    final menu = state.menu;
    final reviews = state.reviews;

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(store),
        SliverToBoxAdapter(child: _buildInfoSection(store)),
        if (menu.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Menu',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => MenuItemCard(
                item: menu[i],
                onTap: () {
                  final offers = menu[i]['offers'] as List<dynamic>?;
                  if (offers != null && offers.isNotEmpty) {
                    final offerId = (offers.first as Map<String, dynamic>)['id'] as String?;
                    if (offerId != null) context.go('/offers/$offerId');
                  }
                },
              ),
              childCount: menu.length,
            ),
          ),
        ],
        if (reviews.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Reviews',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _buildReviewCard(reviews[i]),
              childCount: reviews.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildSliverAppBar(Store store) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: store.coverImageUrl != null
            ? Image.network(store.coverImageUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholderImage())
            : _placeholderImage(),
      ),
    );
  }

  Widget _placeholderImage() {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(child: Icon(Icons.store, size: 64, color: theme.colorScheme.onSurfaceVariant)),
    );
  }

  Widget _buildInfoSection(Store store) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(store.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              StarRating(rating: store.ratingAvg, count: store.ratingCount),
              const SizedBox(width: 16),
              Icon(Icons.location_on, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(store.city, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          if (store.description != null) ...[
            const SizedBox(height: 8),
            Text(store.description!, style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
          ],
          if (store.distanceM != null && store.distanceM! > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.near_me, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  store.distanceM! < 1000
                      ? '${store.distanceM!.toStringAsFixed(0)} m away'
                      : '${(store.distanceM! / 1000).toStringAsFixed(1)} km away',
                  style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
          if (store.opensAt != null && store.closesAt != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${store.opensAt} - ${store.closesAt}',
                    style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('View on Map'),
              onPressed: () {
                if (store.lat != 0 && store.lng != 0) {
                  context.go('/map?lat=${store.lat}&lng=${store.lng}');
                } else {
                  context.go('/map');
                }
              },
            ),
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final theme = Theme.of(context);
    final rating = review['rating'] as int? ?? 0;
    final comment = review['comment'] as String?;
    final imageUrl = review['imageUrl'] as String?;
    final customer = review['customer'] as Map<String, dynamic>?;
    final customerName = customer?['email'] as String? ?? 'Anonymous';
    final createdAt = review['created_at'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text(customerName[0].toUpperCase(), style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(customerName, style: const TextStyle(fontWeight: FontWeight.w500))),
                StarRating(rating: rating.toDouble()),
              ],
            ),
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comment, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
            ],
            if (imageUrl != null && imageUrl.isNotEmpty) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox()),
              ),
            ],
            if (createdAt.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(createdAt, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }
}
