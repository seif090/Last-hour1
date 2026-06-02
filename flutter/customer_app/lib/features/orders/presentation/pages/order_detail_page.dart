import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/order_track_bloc.dart';
import '../widgets/status_timeline.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/error_screen.dart';
import '../../../../core/widgets/star_rating.dart';
import '../../../../services/api_client.dart';
import '../../../../injector.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;
  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late final OrderTrackBloc _bloc;
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submittingReview = false;
  bool _reviewSubmitted = false;
  String? _reviewImageUrl;

  @override
  void initState() {
    super.initState();
    _bloc = OrderTrackBloc(api: sl<ApiClient>(), ws: sl<WebSocketService>());
    _bloc.add(LoadOrderDetail(widget.orderId));
  }

  @override
  void dispose() {
    _bloc.close();
    _commentCtrl.dispose();
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
                            if (order.discountAmount > 0) ...[
                              _row('Discount', '-${order.discountAmount.toStringAsFixed(2)} ${order.currency}',
                                  bold: true),
                              if (order.couponCode != null)
                                _row('Coupon', order.couponCode!),
                            ],
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
                      if (order.status == 'pending' || order.status == 'confirmed') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _confirmCancel(order.id),
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                            label: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.red),
                              minimumSize: const Size(double.infinity, 48),
                            ),
                          ),
                        ),
                      ],
                      if (order.status == 'picked_up' || order.status == 'cancelled') ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => context.go('/offers/${order.offerId}'),
                            icon: const Icon(Icons.replay),
                            label: const Text('Reorder'),
                          ),
                        ),
                      ],
                    if (order.status == 'picked_up') ...[
                      const SizedBox(height: 24),
                      _buildReviewSection(order),
                    ],
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

  Widget _buildReviewSection(dynamic order) {
    if (_reviewSubmitted) {
      return Card(
        color: Colors.green.shade50,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 12),
              Text('Review submitted! Thank you.', style: TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leave a Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  icon: Icon(
                    star <= _rating ? Icons.star : Icons.star_border,
                    color: star <= _rating ? Colors.amber : Colors.grey.shade300,
                    size: 36,
                  ),
                  onPressed: _submittingReview ? null : () => setState(() => _rating = star),
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _commentCtrl,
              decoration: const InputDecoration(
                labelText: 'Comment (optional)',
                border: OutlineInputBorder(),
                hintText: 'Share your experience...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _pickReviewImage(),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(_reviewImageUrl != null ? 'Change Photo' : 'Add Photo'),
                ),
                if (_reviewImageUrl != null) ...[
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(_reviewImageUrl!, width: 48, height: 48, fit: BoxFit.cover),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () => setState(() => _reviewImageUrl = null),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _rating > 0 && !_submittingReview ? () => _submitReview(order.id) : null,
                child: _submittingReview
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit Review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(String orderId) async {
    setState(() => _submittingReview = true);
    try {
      final api = sl<ApiClient>();
      final response = await api.post('/api/v1/reviews', body: {
        'orderId': orderId,
        'rating': _rating,
        'comment': _commentCtrl.text.trim().isNotEmpty ? _commentCtrl.text.trim() : null,
        'imageUrl': _reviewImageUrl,
      });
      if (response.isSuccess) {
        setState(() {
          _submittingReview = false;
          _reviewSubmitted = true;
        });
      } else {
        setState(() => _submittingReview = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Failed to submit review')),
          );
        }
      }
    } catch (e) {
      setState(() => _submittingReview = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _confirmCancel(String orderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Order')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(CancelOrder(orderId));
            },
            child: const Text('Cancel Order', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _pickReviewImage() {
    final ctrl = TextEditingController(text: _reviewImageUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Photo URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Paste image URL',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final url = ctrl.text.trim();
              if (url.isNotEmpty) {
                setState(() => _reviewImageUrl = url);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
