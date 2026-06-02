import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/order_track_bloc.dart';
import '../widgets/order_card.dart';
import '../../../../core/widgets/error_screen.dart';
import '../../../../core/widgets/infinite_scroll_list.dart';
import '../../../../services/api_client.dart';
import '../../../../services/websocket_service.dart';
import '../../../../injector.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrderTrackBloc _bloc;
  String? _selectedStatus;
  String? _startDate;
  String? _endDate;
  double? _minPrice;
  double? _maxPrice;
  String? _sort;

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

  void _reload() {
    _bloc.add(LoadOrders(
      refresh: true,
      status: _selectedStatus,
      startDate: _startDate,
      endDate: _endDate,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      sort: _sort,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
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
                onRetry: _reload,
              );
            }
            if (state is OrdersLoaded) {
              if (state.orders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_long, size: 64, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No orders yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 16)),
                      if (_selectedStatus != null) ...[
                        const SizedBox(height: 8),
                        TextButton(onPressed: () {
                          setState(() {
                            _selectedStatus = null;
                            _startDate = null;
                            _endDate = null;
                            _minPrice = null;
                            _maxPrice = null;
                            _sort = null;
                          });
                          _reload();
                        }, child: const Text('Clear filters')),
                      ],
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: InfiniteScrollList(
                  itemCount: state.orders.length,
                  isLoading: state.isLoadingMore,
                  hasMore: state.hasMore,
                  onLoadMore: () => _bloc.add(LoadMoreOrders()),
                  itemBuilder: (i) => OrderCard(
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

  void _showFilterSheet(BuildContext context) {
    String? tempStatus = _selectedStatus;
    String? tempStart = _startDate;
    String? tempEnd = _endDate;
    String? tempSort = _sort;
    final minCtrl = TextEditingController(text: _minPrice?.toStringAsFixed(0) ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toStringAsFixed(0) ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Filter Orders', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const Text('Status', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['pending', 'confirmed', 'preparing', 'ready', 'picked_up', 'cancelled'].map((s) {
                  final selected = tempStatus == s;
                  return ChoiceChip(
                    label: Text(s[0].toUpperCase() + s.substring(1)),
                    selected: selected,
                    onSelected: (_) => setSheetState(() => tempStatus = selected ? null : s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Sort: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  DropdownButton<String?>(
                    value: tempSort,
                    hint: const Text('Newest'),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Newest')),
                      DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                      DropdownMenuItem(value: 'amount_asc', child: Text('Price: Low to High')),
                      DropdownMenuItem(value: 'amount_desc', child: Text('Price: High to Low')),
                    ],
                    onChanged: (v) => setSheetState(() => tempSort = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minCtrl,
                      decoration: const InputDecoration(labelText: 'Min Price', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: maxCtrl,
                      decoration: const InputDecoration(labelText: 'Max Price', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedStatus = tempStatus;
                    _startDate = tempStart;
                    _endDate = tempEnd;
                    _sort = tempSort;
                    _minPrice = double.tryParse(minCtrl.text);
                    _maxPrice = double.tryParse(maxCtrl.text);
                  });
                  _reload();
                  Navigator.pop(ctx);
                },
                child: const Text('Apply Filters'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
