import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/offer_detail_bloc.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../../../core/widgets/error_screen.dart';
import '../../../home/presentation/widgets/offer_timer.dart';
import '../../../home/presentation/widgets/stock_indicator.dart';
import '../../../../injector.dart';

class OfferDetailPage extends StatefulWidget {
  final String offerId;
  const OfferDetailPage({super.key, required this.offerId});

  @override
  State<OfferDetailPage> createState() => _OfferDetailPageState();
}

class _OfferDetailPageState extends State<OfferDetailPage> {
  late final OfferDetailBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = OfferDetailBloc(api: sl<ApiClient>(), ws: sl<WebSocketService>());
    _bloc.add(LoadOfferDetail(widget.offerId));
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
        child: BlocConsumer<OfferDetailBloc, OfferDetailState>(
          listener: (context, state) {
            if (state is OrderPlaced) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
              context.go('/orders/${state.orderId}');
            }
            if (state is OfferDetailError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is OfferDetailLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OfferDetailError && state is! OfferDetailLoaded) {
              return ErrorScreen(
                message: state.message,
                onRetry: () => _bloc.add(LoadOfferDetail(widget.offerId)),
              );
            }
            if (state is OfferDetailLoaded) {
              final offer = state.offer;
              return LoadingOverlay(
                isLoading: state.isPlacingOrder,
                message: 'Placing order...',
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(context, offer),
                    SliverToBoxAdapter(child: _buildBody(context, state)),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, dynamic offer) {
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: offer.imageUrl != null
            ? Image.network(offer.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholderImage())
            : _placeholderImage(),
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.restaurant, size: 64, color: Colors.grey)));
  }

  Widget _buildBody(BuildContext context, OfferDetailLoaded state) {
    final offer = state.offer;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(offer.storeName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ),
              OfferTimer(endTime: offer.endTime),
            ],
          ),
          const SizedBox(height: 8),
          Text(offer.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(offer.productName, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${offer.discountedPrice.toStringAsFixed(0)} EGP',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                '${offer.originalPrice.toStringAsFixed(0)} EGP',
                style: const TextStyle(fontSize: 18, color: Colors.grey, decoration: TextDecoration.lineThrough),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '-${offer.discountPercent.toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StockIndicator(remaining: offer.stockRemaining, initial: offer.stockInitial),
              const Spacer(),
              if (offer.distanceM > 0)
                Text(
                  offer.distanceM < 1000
                      ? '${offer.distanceM.toStringAsFixed(0)} m away'
                      : '${(offer.distanceM / 1000).toStringAsFixed(1)} km away',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (!offer.isSoldOut) ...[
            Row(
              children: [
                IconButton(
                  onPressed: state.quantity > 1 ? () => _bloc.add(PlaceOrder(state.quantity - 1)) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  iconSize: 32,
                ),
                const SizedBox(width: 16),
                Text('${state.quantity}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: state.quantity < offer.maxPerCustomer && state.quantity < offer.stockRemaining
                      ? () => _bloc.add(PlaceOrder(state.quantity + 1))
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  iconSize: 32,
                ),
                const Spacer(),
                Text(
                  'Max ${offer.maxPerCustomer}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Order Now — ${(offer.discountedPrice * state.quantity).toStringAsFixed(0)} EGP',
              onPressed: () => _bloc.add(PlaceOrder(state.quantity)),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.sold_out, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sold out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
