import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lasthour_shared/models/order.dart';
import '../bloc/incoming_orders_bloc.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

class MerchantIncomingOrdersPage extends StatefulWidget {
  const MerchantIncomingOrdersPage({super.key});

  @override
  State<MerchantIncomingOrdersPage> createState() => _MerchantIncomingOrdersPageState();
}

class _MerchantIncomingOrdersPageState extends State<MerchantIncomingOrdersPage> {
  late final IncomingOrdersBloc _bloc;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _bloc = sl<IncomingOrdersBloc>();
    _bloc.add(const LoadIncomingOrders());
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _bloc.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      if (_bloc.state is IncomingOrdersLoaded) {
        final s = _bloc.state as IncomingOrdersLoaded;
        if (!s.isLoadingMore && s.hasMore) {
          _bloc.add(LoadMoreOrders());
        }
      }
    }
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
            final theme = Theme.of(context);
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
                  controller: _scrollCtrl,
                  children: [
                    if (pending.isNotEmpty) _section(context, 'Pending', pending, true),
                    if (active.isNotEmpty) _section(context, 'Active', active, false),
                    if (ready.isNotEmpty) _section(context, 'Ready', ready, false),
                    if (completed.isNotEmpty) _section(context, 'Completed', completed, false),
                    if (state.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (!state.hasMore && state.orders.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text('All orders loaded', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
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

  Widget _section(BuildContext context, String title, List<Order> orders, bool showActions) {
    final theme = Theme.of(context);
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
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _bloc.add(AcceptOrder(order.id)),
                          style: ElevatedButton.styleFrom(backgroundColor: theme.colorScheme.tertiary),
                          child: const Text('Accept'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _bloc.add(OrderStatusChanged(order.id, 'cancelled')),
                          style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
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
                if (order.status == 'ready') ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showQrCode(context, order),
                    icon: const Icon(Icons.qr_code, size: 18),
                    label: const Text('Show QR'),
                  ),
                ],
                if (order.status == 'pickedUp') ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showInvoice(context, order),
                    icon: const Icon(Icons.receipt, size: 18),
                    label: const Text('Invoice'),
                  ),
                ],
              ],
            ),
          ),
        )),
      ],
    );
  }

  void _showQrCode(BuildContext context, Order order) {
    final orderNumber = order.orderNumber;
    showDialog<String>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return AlertDialog(
          title: const Text('Order QR Code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Order #$orderNumber', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=lasthour://orders/$orderNumber',
                  width: 200,
                  height: 200,
                  errorBuilder: (_, __, ___) => Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.surfaceContainerHighest),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(orderNumber, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        );
      },
    );
  }

  Future<void> _showInvoice(BuildContext context, Order order) async {
    final api = sl<ApiClient>();
    final resp = await api.get('/api/v1/merchant/orders/${order.id}/invoice');
    if (!resp.isSuccess || resp.data == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp.error ?? 'Failed to load invoice')));
      }
      return;
    }
    final data = resp.data!;
    final d = data['data'] as Map<String, dynamic>? ?? data;
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Invoice', style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold))),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(height: 24),
              _invoiceRow(theme, 'Invoice #', d['invoiceNumber'] as String? ?? ''),
              _invoiceRow(theme, 'Order #', d['orderNumber'] as String? ?? ''),
              _invoiceRow(theme, 'Date', d['createdAt'] as String? ?? ''),
              if (d['store'] != null) ...[
                const SizedBox(height: 16),
                Text('Store', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                _invoiceRow(theme, 'Name', (d['store'] as Map)['name'] as String? ?? ''),
                _invoiceRow(theme, 'Address', (d['store'] as Map)['address_line1'] as String? ?? ''),
              ],
              if (d['customer'] != null) ...[
                const SizedBox(height: 16),
                Text('Customer', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                _invoiceRow(theme, 'Email', (d['customer'] as Map)['email'] as String? ?? ''),
                _invoiceRow(theme, 'Phone', (d['customer'] as Map)['phone'] as String? ?? ''),
              ],
              const Divider(height: 24),
              Text('Items', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
              ...((d['items'] as List?)?.map((item) {
                final i = item as Map<String, dynamic>;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(i['name'] as String? ?? 'Item'),
                  trailing: Text('${i['quantity'] ?? 1}x — ${(i['price'] as num?)?.toStringAsFixed(0) ?? ''} EGP'),
                );
              }) ?? []),
              const Divider(height: 24),
              _invoiceRow(theme, 'Subtotal', '${(d['subtotal'] as num?)?.toStringAsFixed(0) ?? '0'} EGP'),
              if ((d['discountAmount'] as num?) != null && (d['discountAmount'] as num) > 0) ...[
                _invoiceRow(theme, 'Discount', '-${(d['discountAmount'] as num).toStringAsFixed(0)} EGP'),
                if (d['couponCode'] != null) _invoiceRow(theme, 'Coupon', d['couponCode'] as String),
              ],
              _invoiceRow(theme, 'Service Fee', '${(d['serviceFee'] as num?)?.toStringAsFixed(0) ?? '0'} EGP'),
              const Divider(thickness: 2),
              _invoiceRow(theme, 'Total', '${(d['totalAmount'] as num?)?.toStringAsFixed(0) ?? '0'} EGP', bold: true),
              if (d['payment'] != null) ...[
                const SizedBox(height: 16),
                Text('Payment', style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                _invoiceRow(theme, 'Method', (d['payment'] as Map)['provider'] as String? ?? ''),
                _invoiceRow(theme, 'Status', (d['payment'] as Map)['status'] as String? ?? ''),
              ],
            ],
          ),
        ),
      );
    },
  );
  }

  Widget _invoiceRow(ThemeData theme, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
