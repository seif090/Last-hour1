import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

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

  Future<void> _downloadCsv() async {
    try {
      final csv = await _api.downloadString('/api/v1/merchant/report/csv', queryParams: {'days': '$_days'});
      if (csv == null) return;
      final file = File('${Directory.systemTemp.path}/lasthour_report_$_days.csv');
      await file.writeAsString(csv);
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV saved to ${file.path} and copied to clipboard')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to download CSV')));
      }
    }
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download CSV Report',
            onPressed: _downloadCsv,
          ),
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
                                theme.colorScheme.primary,
                              ),
                              _metricCard(
                                'Total Revenue',
                                '${(_analytics!['totalRevenue'] as num? ?? 0).toStringAsFixed(0)} EGP',
                                Icons.currency_pound,
                                theme.colorScheme.tertiary,
                              ),
                              _metricCard(
                                'Stores',
                                '${_analytics!['stores'] ?? 0}',
                                Icons.store,
                                theme.colorScheme.secondary,
                              ),
                              _metricCard(
                                'Avg Daily Orders',
                                '${_days > 0 ? ((_analytics!['totalOrders'] as num? ?? 0) / _days).toStringAsFixed(1) : 0}',
                                Icons.trending_up,
                                theme.colorScheme.tertiary,
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
    final theme = Theme.of(context);
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
            Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRow(Map<String, dynamic> day) {
    final theme = Theme.of(context);
    final date = day['date'] as String? ?? '';
    final orders = day['orders'] as int? ?? 0;
    final revenue = (day['revenue'] as num?)?.toDouble() ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        dense: true,
        title: Text(date),
        trailing: Text('$orders orders · ${revenue.toStringAsFixed(0)} EGP',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13)),
      ),
    );
  }
}
