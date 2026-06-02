import 'package:flutter/material.dart';
import '../../../injector.dart';
import '../../../services/api_client.dart';

class MerchantAnalyticsPage extends StatefulWidget {
  const MerchantAnalyticsPage({super.key});

  @override
  State<MerchantAnalyticsPage> createState() => _MerchantAnalyticsPageState();
}

class _MerchantAnalyticsPageState extends State<MerchantAnalyticsPage> {
  final _api = sl<ApiClient>();
  Map<String, dynamic>? _analytics;
  bool _loading = true;
  int _days = 30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/api/v1/merchant/analytics?days=$_days');
      if (response.isSuccess && response.data != null) {
        setState(() => _analytics = response.data);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (days) {
              setState(() => _days = days);
              _load();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: _analytics == null
                    ? const Center(child: Text('No data available'))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              _metricCard(
                                'Total Orders',
                                '${_analytics!['totalOrders'] ?? 0}',
                                Icons.receipt_long,
                                Colors.blue,
                              ),
                              _metricCard(
                                'Total Revenue',
                                '${(_analytics!['totalRevenue'] as num? ?? 0).toStringAsFixed(0)} EGP',
                                Icons.currency_pound,
                                Colors.green,
                              ),
                              _metricCard(
                                'Stores',
                                '${_analytics!['stores'] ?? 0}',
                                Icons.store,
                                Colors.orange,
                              ),
                              _metricCard(
                                'Avg Daily Orders',
                                '${_days > 0 ? ((_analytics!['totalOrders'] as num? ?? 0) / _days).toStringAsFixed(1) : 0}',
                                Icons.trending_up,
                                Colors.purple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('Daily Breakdown',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ...(_analytics!['daily'] as List<dynamic>? ?? []).map(
                            (d) => _buildDailyRow(d as Map<String, dynamic>),
                          ),
                        ],
                      ),
              ),
            ),
    );
  }

  Widget _metricCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRow(Map<String, dynamic> day) {
    final date = day['date'] as String? ?? '';
    final orders = day['orders'] as int? ?? 0;
    final revenue = (day['revenue'] as num?)?.toDouble() ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        title: Text(date),
        trailing: Text('$orders orders · ${revenue.toStringAsFixed(0)} EGP',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      ),
    );
  }
}
