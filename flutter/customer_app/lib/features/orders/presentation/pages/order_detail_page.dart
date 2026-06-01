import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/order_track_bloc.dart';
import '../widgets/status_timeline.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_screen.dart';
import '../../../../injector.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrderTrackBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = OrderTrackBloc(api: sl<ApiClient>(), ws: sl<WebSocketService>());
    _bloc.add(LoadOrderDetail(widget.orderId));
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<OrderTrackBloc, OrderTrackState>(
          builder: (context, state) {
            if (state is OrderTrackInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is OrderTrackError) {
              return ErrorScreen(
                message: state.message,
                onRetry: () => _bloc.add(LoadOrderDetail(widget.orderId)),
              );
            }
            if (state is OrderDetailLoaded) {
              final order = state.order;
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Order #${order.orderNumber}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                _statusChip(order.status),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(order.storeName, style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 4),
                            Text(order.offerTitle, style: TextStyle(color: Colors.grey.shade600)),
                            const SizedBox(height: 16),
                            const Divider(),
                            _row('Quantity', '${order.quantity}'),
                            _row('Subtotal', '${order.subtotal.toStringAsFixed(2)} ${order.currency}'),
                            _row('Service Fee', '${order.serviceFee.toStringAsFixed(2)} ${order.currency}'),
                            const Divider(),
                            _row('Total', '${order.totalAmount.toStringAsFixed(2)} ${order.currency}',
                                bold: true),
                            if (order.estimatedReadyAt != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.schedule, size: 16, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text('Estimated ready: ${order.estimatedReadyAt}'),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Status', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    StatusTimeline(statusHistory: order.statusHistory),
                    if (order.storeLat != null && order.storeLng != null) ...[
                      const SizedBox(height: 24),
                      AppButton(
                        label: 'View on Map',
                        icon: Icons.map,
                        isOutlined: true,
                        onPressed: () {
                          // Navigate to store location
                        },
                      ),
                    ],
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Track Order',
                      icon: Icons.timeline,
                      onPressed: () => context.go('/orders/${order.id}/track'),
                    ),
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

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal, fontSize: bold ? 16 : 14)),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'pending':
        color = Colors.orange;
      case 'confirmed':
        color = Colors.blue;
      case 'preparing':
        color = Colors.purple;
      case 'ready':
        color = Colors.green;
      case 'pickedUp':
        color = Colors.grey;
      case 'cancelled':
        color = Colors.red;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(status[0].toUpperCase() + status.substring(1),
          style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
