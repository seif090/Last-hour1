import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/admin_auth_bloc.dart';
import '../../../../services/api_client.dart';
import '../../../../injector.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  final _api = sl<ApiClient>();
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/api/v1/admin/stats');
      if (response.isSuccess && response.data != null) {
        setState(() => _stats = response.data!['data'] as Map<String, dynamic>? ?? response.data);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AdminAuthBloc>().add(AdminLogout()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: SingleChildScrollView(
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
                          _card('Users', '${_stats?['totalUsers'] ?? 0}', Icons.people, theme.colorScheme.primary),
                          _card('Merchants', '${_stats?['totalMerchants'] ?? 0}', Icons.store, theme.colorScheme.secondary),
                          _card('Stores', '${_stats?['totalStores'] ?? 0}', Icons.storefront, Colors.amber),
                          _card('Orders', '${_stats?['totalOrders'] ?? 0}', Icons.receipt_long, theme.colorScheme.tertiary),
                          _card('Revenue', '${_stats?['totalRevenue'] ?? 0}', Icons.currency_pound, theme.colorScheme.tertiary),
                          _card('Active Offers', '${_stats?['activeOffers'] ?? 0}', Icons.local_offer, theme.colorScheme.error),
                          _card('Orders Today', '${_stats?['ordersToday'] ?? 0}', Icons.today, theme.colorScheme.tertiary),
                        ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _card(String label, String value, IconData icon, Color color) {
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
            Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
