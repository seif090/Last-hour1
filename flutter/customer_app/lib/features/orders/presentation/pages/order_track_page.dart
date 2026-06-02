import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/order_track_bloc.dart';
import '../widgets/status_timeline.dart';
import '../../../../core/widgets/error_screen.dart';
import '../../../../injector.dart';

class OrderTrackPage extends StatefulWidget {
  final String orderId;
  const OrderTrackPage({super.key, required this.orderId});

  @override
  State<OrderTrackPage> createState() => _OrderTrackPageState();
}

class _OrderTrackPageState extends State<OrderTrackPage> {
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
      appBar: AppBar(title: const Text('Track Order')),
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
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _buildStatusIcon(order.status),
                    const SizedBox(height: 16),
                    Text(
                      'Order #${order.orderNumber}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order.storeName,
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 32),
                    StatusTimeline(
                      statusHistory: order.statusHistory,
                      currentStatus: order.status,
                    ),
                    if (order.estimatedReadyAt != null) ...[
                      const SizedBox(height: 32),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.schedule, color: Colors.orange),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Estimated ready time',
                                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  Text(order.estimatedReadyAt!,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (order.status == 'ready')
                      ElevatedButton.icon(
                        onPressed: () => _bloc.add(ConfirmPickup(order.id)),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Mark as Picked Up'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                        ),
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

  Widget _buildStatusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'pending':
        icon = Icons.hourglass_empty;
        color = Colors.orange;
      case 'confirmed':
        icon = Icons.check_circle_outline;
        color = Colors.blue;
      case 'preparing':
        icon = Icons.restaurant;
        color = Colors.purple;
      case 'ready':
        icon = Icons.rocket_launch;
        color = Colors.green;
      case 'pickedUp':
        icon = Icons.check_circle;
        color = Colors.grey;
      default:
        icon = Icons.cancel;
        color = Colors.red;
    }

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
      ),
      child: Icon(icon, size: 50, color: color),
    );
  }
}
