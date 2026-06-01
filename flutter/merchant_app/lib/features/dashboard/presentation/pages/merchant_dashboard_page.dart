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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/api/v1/merchant/dashboard');
      if (response.isSuccess && response.data != null) {
        setState(() {
          _dashboard = response.data;
          _loading = false;
        });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
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
                        MetricCard(
                          label: 'Active Offers',
                          value: '${_dashboard?['active_offers'] ?? 0}',
                          icon: Icons.local_offer,
                        ),
                        MetricCard(
                          label: 'Today\'s Orders',
                          value: '${_dashboard?['today_orders'] ?? 0}',
                          icon: Icons.receipt_long,
                        ),
                        MetricCard(
                          label: 'Today\'s Revenue',
                          value: '${(_dashboard?['today_revenue'] ?? 0).toStringAsFixed(0)} EGP',
                          icon: Icons.currency_pound,
                          color: Colors.green,
                        ),
                        MetricCard(
                          label: 'Pending Orders',
                          value: '${_dashboard?['pending_orders'] ?? 0}',
                          icon: Icons.hourglass_empty,
                          color: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_dashboard?['hourly_sales'] != null)
                      HourlyChart(
                        hourlyData: (_dashboard!['hourly_sales'] as List)
                            .map((e) => (e as num).toDouble())
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
