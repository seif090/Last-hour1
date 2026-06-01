import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/order_track_bloc.dart';
import '../widgets/order_card.dart';
import '../../../../core/widgets/error_screen.dart';
import '../../../../injector.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrderTrackBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = OrderTrackBloc(api: sl<ApiClient>(), ws: sl<WebSocketService>());
    _bloc.add(const LoadOrders());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<OrderTrackBloc, OrderTrackState>(
          builder: (context, state) {
            if (state is OrdersLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OrderTrackError) {
              return ErrorScreen(
                message: state.message,
                onRetry: () => _bloc.add(const LoadOrders()),
              );
            }
            if (state is OrdersLoaded) {
              if (state.orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No orders yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _bloc.add(const LoadOrders()),
                child: ListView.builder(
                  itemCount: state.orders.length,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (_, i) => OrderCard(
                    order: state.orders[i],
                    onTap: () => context.go('/orders/${state.orders[i].id}'),
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
