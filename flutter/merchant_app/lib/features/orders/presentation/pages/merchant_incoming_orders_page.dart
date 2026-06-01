import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/incoming_orders_bloc.dart';
import '../../../services/api_client.dart';
import '../../../services/websocket_service.dart';

class MerchantIncomingOrdersPage extends StatefulWidget {
  const MerchantIncomingOrdersPage({super.key});

  @override
  State<MerchantIncomingOrdersPage> createState() => _MerchantIncomingOrdersPageState();
}

class _MerchantIncomingOrdersPageState extends State<MerchantIncomingOrdersPage> {
  late final IncomingOrdersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = IncomingOrdersBloc(
      api: ApiClient(baseUrl: 'http://localhost:3000'),
      ws: MerchantWebSocketService(
        baseUrl: 'ws://localhost:3000',
        token: '',  // Will be set after auth
        merchantId: '',
      ),
    );
    _bloc.add(const LoadIncomingOrders());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Orders')),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocConsumer<IncomingOrdersBloc, IncomingOrdersState>(
          listener: (ctx, state) {
            if (state is IncomingOrdersError) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message)));
            }
            if (state is OrderActionSuccess) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is IncomingOrdersLoading && state is! IncomingOrdersLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is IncomingOrdersLoaded) {
              final pending = state.orders.where((o) => o.status == 'pending').toList();
              final active = state.orders.where((o) => o.status == 'confirmed' || o.status == 'preparing').toList();
              final ready = state.orders.where((o) => o.status == 'ready').toList();
              final completed = state.orders.where((o) => o.status == 'pickedUp' || o.status == 'cancelled').toList();

              if (state.orders.isEmpty) {
                return const Center(child: Text('No orders yet'));
              }

              return RefreshIndicator(
                onRefresh: () async => _bloc.add(const LoadIncomingOrders()),
                child: ListView(
                  children: [
                    if (pending.isNotEmpty) _section(context, 'Pending', pending, true),
                    if (active.isNotEmpty) _section(context, 'Active', active, false),
                    if (ready.isNotEmpty) _section(context, 'Ready', ready, false),
                    if (completed.isNotEmpty) _section(context, 'Completed', completed, false),
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

  Widget _section(BuildContext context, String title, List<dynamic> orders, bool showActions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ...orders.map((order) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('#${order.orderNumber} — ${order.offerTitle}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${order.quantity}x — ${order.totalAmount.toStringAsFixed(0)} EGP',
                    style: TextStyle(color: Colors.grey.shade600)),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _bloc.add(AcceptOrder(order.id)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _bloc.add(OrderStatusChanged(order.id, 'cancelled')),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Decline'),
                        ),
                      ),
                    ],
                  ),
                ] else if (order.status == 'confirmed' || order.status == 'preparing') ...[
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _bloc.add(MarkReady(order.id)),
                    child: const Text('Mark Ready'),
                  ),
                ],
              ],
            ),
          ),
        )),
      ],
    );
  }
}
