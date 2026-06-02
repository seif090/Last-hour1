import 'package:flutter/material.dart';
import '../widgets/metric_card.dart';
import '../widgets/hourly_chart.dart';
import '../../../injector.dart';
import '../../../services/api_client.dart';

class MerchantDashboardPage extends StatefulWidget {
  const MerchantDashboardPage({super.key});

  @override
  State<MerchantDashboardPage> createState() => _MerchantDashboardPageState();
}

class _MerchantDashboardPageState extends State<MerchantDashboardPage> {
  final _api = sl<ApiClient>();
  Map<String, dynamic>? _dashboard;
  List<Map<String, dynamic>> _stores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _api.get('/api/v1/merchant/dashboard'),
        _api.get('/api/v1/merchant/sales/today'),
      ]);
      final dashResp = results[0];
      final salesResp = results[1];

      if (dashResp.isSuccess && dashResp.data != null) {
        final storesRaw = dashResp.data!['stores'] as List<dynamic>? ?? [];
        setState(() {
          _stores = storesRaw.cast<Map<String, dynamic>>();
          _dashboard = dashResp.data;
        });
      }
      if (salesResp.isSuccess && salesResp.data != null) {
        setState(() {
          _dashboard ??= {};
          _dashboard!.addAll(Map<String, dynamic>.from(salesResp.data!));
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final activeOffers = _stores.fold<int>(0, (sum, s) {
      final offers = s['offers'] as List<dynamic>? ?? [];
      return sum + offers.length;
    });
    final totalOrders = _stores.fold<int>(0, (sum, s) {
      final count = s['_count'] as Map<String, dynamic>?;
      return sum + (count?['orders'] as int? ?? 0);
    });
    final totalProducts = _stores.fold<int>(0, (sum, s) {
      final count = s['_count'] as Map<String, dynamic>?;
      return sum + (count?['products'] as int? ?? 0);
    });
    final todayRevenue = (_dashboard?['total_revenue'] as num?)?.toDouble() ?? 0;
    final todayOrders = (_dashboard?['total_orders'] as int?) ?? 0;
    final hourlyData = (_dashboard?['orders_by_hour'] as List<dynamic>?)
            ?.map((e) => (e as Map<String, dynamic>)['count'] as int? ?? 0)
            .toList() ??
        [];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_stores.length > 1)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text('${_stores.length} stores', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        MetricCard(label: 'Active Offers', value: '$activeOffers', icon: Icons.local_offer),
                        MetricCard(label: "Today's Orders", value: '$todayOrders', icon: Icons.receipt_long),
                        MetricCard(label: "Today's Revenue", value: '${todayRevenue.toStringAsFixed(0)} EGP', icon: Icons.currency_pound, color: Colors.green),
                        MetricCard(label: 'Total Products', value: '$totalProducts', icon: Icons.inventory_2, color: Colors.blue),
                      ],
                    ),
                    if (hourlyData.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      HourlyChart(hourlyData: hourlyData.map((e) => e.toDouble()).toList()),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.discount_outlined),
                        label: const Text('Manage Coupons'),
                        onPressed: () => _showCouponManager(context),
                      ),
                    ),
                    if (_stores.length > 1) ...[
                      const SizedBox(height: 24),
                      Text('Stores', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._stores.map((s) => _buildStoreTile(s)),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStoreTile(Map<String, dynamic> store) {
    final name = store['name'] as String? ?? 'Unknown';
    final offers = store['offers'] as List<dynamic>? ?? [];
    final count = store['_count'] as Map<String, dynamic>?;
    final storeId = store['id'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.store)),
        title: Text(name),
        subtitle: Text('${count?['orders'] ?? 0} orders · ${offers.length} active offers'),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'hours') _editHours(context, storeId, name);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'hours', child: Text('Edit Hours')),
          ],
        ),
      ),
    );
  }

  void _editHours(BuildContext context, String storeId, String storeName) {
    final opensCtrl = TextEditingController();
    final closesCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$storeName Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: opensCtrl,
              decoration: const InputDecoration(labelText: 'Opens At (e.g. 08:00)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: closesCtrl,
              decoration: const InputDecoration(labelText: 'Closes At (e.g. 22:00)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final data = <String, dynamic>{};
              if (opensCtrl.text.isNotEmpty) data['opensAt'] = opensCtrl.text;
              if (closesCtrl.text.isNotEmpty) data['closesAt'] = closesCtrl.text;
              await _api.patch('/api/v1/merchant/stores/$storeId/hours', body: data);
              Navigator.pop(ctx);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Store hours updated')),
                );
              }
              _load();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showCouponManager(BuildContext context) {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    final minCtrl = TextEditingController();
    final maxDiscountCtrl = TextEditingController();
    String discountType = 'percentage';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Create Coupon', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextFormField(
                  controller: codeCtrl,
                  decoration: const InputDecoration(labelText: 'Coupon Code', border: OutlineInputBorder(), hintText: 'e.g. SUMMER20'),
                  textCapitalization: TextCapitalization.characters,
                  validator: (v) => v != null && v.length >= 3 ? null : 'Min 3 characters',
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: discountType,
                  decoration: const InputDecoration(labelText: 'Discount Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'percentage', child: Text('Percentage')),
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed Amount')),
                  ],
                  onChanged: (v) => setSheetState(() => discountType = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: valueCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: discountType == 'percentage' ? 'Discount %' : 'Discount Amount (EGP)',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (v) => v != null && double.tryParse(v) != null && double.parse(v) > 0 ? null : 'Valid value required',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min Order Amount (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: maxDiscountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max Discount (optional, for % type)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    if (_stores.isEmpty) return;
                    final storeId = _stores.first['id'] as String;
                    final body = <String, dynamic>{
                      'storeId': storeId,
                      'code': codeCtrl.text,
                      'discountType': discountType,
                      'discountValue': double.parse(valueCtrl.text),
                    };
                    if (minCtrl.text.isNotEmpty) body['minOrderAmount'] = double.parse(minCtrl.text);
                    if (maxDiscountCtrl.text.isNotEmpty) body['maxDiscount'] = double.parse(maxDiscountCtrl.text);
                    await _api.post('/api/v1/merchant/coupons', body: body);
                    Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coupon created')),
                      );
                    }
                  },
                  child: const Text('Create Coupon'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
