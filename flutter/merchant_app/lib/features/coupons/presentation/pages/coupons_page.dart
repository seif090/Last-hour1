import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/coupons_bloc.dart';
import '../../models/coupon.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

class CouponsPage extends StatefulWidget {
  const CouponsPage({super.key});

  @override
  State<CouponsPage> createState() => _CouponsPageState();
}

class _CouponsPageState extends State<CouponsPage> {
  late final CouponsBloc _bloc;
  final _api = sl<ApiClient>();
  List<Map<String, dynamic>> _stores = [];
  bool _storesLoading = true;

  @override
  void initState() {
    super.initState();
    _bloc = CouponsBloc(api: _api);
    _loadStores();
  }

  Future<void> _loadStores() async {
    try {
      final resp = await _api.get('/api/v1/merchant/dashboard');
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data!['stores'] as List<dynamic>? ?? [];
        _stores = raw.cast<Map<String, dynamic>>();
        if (_stores.isNotEmpty) {
          _bloc.add(LoadCoupons(_stores.first['id'] as String));
        }
      }
    } catch (_) {}
    setState(() => _storesLoading = false);
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coupons'),
        actions: [
          if (_stores.length > 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.store),
              tooltip: 'Select store',
              onSelected: (id) => _bloc.add(LoadCoupons(id)),
              itemBuilder: (_) => _stores.map((s) => PopupMenuItem(
                value: s['id'] as String,
                child: Text(s['name'] as String? ?? 'Store'),
              )).toList(),
            ),
          if (_bloc.state is CouponsLoaded)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showCreateSheet(context),
            ),
        ],
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<CouponsBloc, CouponsState>(
          builder: (context, state) {
            final theme = Theme.of(context);
            if (_storesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (_stores.isEmpty) {
              return const Center(child: Text('No stores found'));
            }
            if (state is CouponsInitial) {
              return const Center(child: Text('Loading coupons...'));
            }
            if (state is CouponsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CouponsError) {
              return Center(child: Text(state.message));
            }
            if (state is CouponsLoaded) {
              if (state.coupons.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_giftcard, size: 64, color: theme.colorScheme.surfaceContainerHighest),
                      const SizedBox(height: 16),
                      Text('No coupons yet', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Coupon'),
                        onPressed: () => _showCreateSheet(context),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _bloc.add(LoadCoupons(state.selectedStoreId!)),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.coupons.length,
                  itemBuilder: (_, i) {
                    final c = state.coupons[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(c.code, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                                ),
                                Switch(
                                  value: c.isActive,
                                  onChanged: (_) => _bloc.add(ToggleCoupon(c.id)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(c.summary, style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                            if (c.description != null) ...[
                              const SizedBox(height: 4),
                              Text(c.description!, style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                            ],
                            const SizedBox(height: 8),
                            Text('Used ${c.currentUses}/${c.maxUses}', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                            if (c.minOrderAmount != null)
                              Text('Min order: ${c.minOrderAmount!.toStringAsFixed(0)} EGP', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                            if (c.maxDiscount != null)
                              Text('Max discount: ${c.maxDiscount!.toStringAsFixed(0)} EGP', style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 12)),
                            if (c.expiresAt != null)
                              Text('Expires: ${c.expiresAt!.substring(0, 10)}', style: TextStyle(color: theme.colorScheme.error, fontSize: 12)),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: c.maxUses > 0 ? c.currentUses / c.maxUses : 0,
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minCtrl = TextEditingController();
    final maxDiscCtrl = TextEditingController();
    final maxUsesCtrl = TextEditingController(text: '100');
    final descCtrl = TextEditingController();
    String discountType = 'percentage';

    String selectedStoreId = _stores.isNotEmpty ? _stores.first['id'] as String : '';
    if (_bloc.state is CouponsLoaded) {
      selectedStoreId = (_bloc.state as CouponsLoaded).selectedStoreId ?? selectedStoreId;
    }

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
              const Text('Create Coupon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (_stores.length > 1) ...[
                DropdownButtonFormField<String>(
                  value: selectedStoreId,
                  decoration: const InputDecoration(labelText: 'Store', border: OutlineInputBorder()),
                  items: _stores.map((s) => DropdownMenuItem(
                    value: s['id'] as String,
                    child: Text(s['name'] as String? ?? 'Store'),
                  )).toList(),
                  onChanged: (v) => setSheetState(() => selectedStoreId = v!),
                ),
                const SizedBox(height: 12),
              ],
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Coupon Code', hintText: 'SUMMER20', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: discountType,
                decoration: const InputDecoration(labelText: 'Discount Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'percentage', child: Text('Percentage (%)')),
                  DropdownMenuItem(value: 'fixed', child: Text('Fixed (EGP)')),
                ],
                onChanged: (v) => setSheetState(() => discountType = v!),
              ),
              const SizedBox(height: 12),
              TextField(controller: valueCtrl, decoration: InputDecoration(labelText: discountType == 'percentage' ? 'Discount %' : 'Discount Amount', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: minCtrl, decoration: const InputDecoration(labelText: 'Min Order Amount (optional)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: maxDiscCtrl, decoration: const InputDecoration(labelText: 'Max Discount (optional)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: maxUsesCtrl, decoration: const InputDecoration(labelText: 'Max Uses', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (codeCtrl.text.trim().isEmpty || valueCtrl.text.trim().isEmpty) return;
                  _bloc.add(CreateCoupon(
                    storeId: selectedStoreId,
                    code: codeCtrl.text.trim().toUpperCase(),
                    discountType: discountType,
                    discountValue: double.parse(valueCtrl.text.trim()),
                    minOrderAmount: double.tryParse(minCtrl.text.trim()),
                    maxDiscount: double.tryParse(maxDiscCtrl.text.trim()),
                    maxUses: int.tryParse(maxUsesCtrl.text.trim()),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  ));
                  Navigator.pop(ctx);
                },
                child: const Text('Create Coupon'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
