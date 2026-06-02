import 'package:flutter/material.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

class AdminCouponsPage extends StatefulWidget {
  const AdminCouponsPage({super.key});

  @override
  State<AdminCouponsPage> createState() => _AdminCouponsPageState();
}

class _AdminCouponsPageState extends State<AdminCouponsPage> {
  final _api = sl<ApiClient>();
  List<dynamic> _coupons = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/api/v1/admin/coupons');
      if (response.isSuccess && response.data != null) {
        _coupons = (response.data!['coupons'] as List? ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coupons')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _coupons.isEmpty
                  ? ListView(child: const Center(child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No coupons found'),
                    )))
                  : ListView.builder(
                      itemCount: _coupons.length,
                      itemBuilder: (_, i) {
                        final c = _coupons[i] as Map<String, dynamic>;
                        final store = c['store'] as Map<String, dynamic>? ?? {};
                        final value = c['discountValue'] ?? c['value'] ?? 0;
                        final type = c['discountType'] ?? c['type'] ?? 'percentage';
                        final minAmount = c['minAmount'] ?? c['minOrderAmount'] ?? 0;
                        final isActive = c['isActive'] as bool? ?? true;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            title: Text(c['code'] as String? ?? ''),
                            subtitle: Text('${store['name'] ?? 'All'} — $type ${value}% — Min $minAmount'),
                            trailing: Icon(
                              isActive ? Icons.check_circle : Icons.cancel,
                              color: isActive ? Colors.green : Colors.red,
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
