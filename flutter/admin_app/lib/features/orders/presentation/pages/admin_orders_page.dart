import 'package:flutter/material.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final _api = sl<ApiClient>();
  List<dynamic> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/api/v1/admin/orders');
      if (response.isSuccess && response.data != null) {
        _orders = (response.data!['data']?['orders'] as List? ?? []);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _orders.length,
                itemBuilder: (_, i) {
                  final o = _orders[i] as Map<String, dynamic>;
                  return ListTile(
                    title: Text('#${o['orderNumber'] ?? ''}'),
                    subtitle: Text('${o['status'] ?? ''} · ${o['totalAmount'] ?? ''} EGP'),
                    trailing: Text(o['createdAt']?.toString().substring(0, 10) ?? ''),
                  );
                },
              ),
            ),
    );
  }
}
