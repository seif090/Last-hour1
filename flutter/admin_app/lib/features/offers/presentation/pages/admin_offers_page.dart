import 'package:flutter/material.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

class AdminOffersPage extends StatefulWidget {
  const AdminOffersPage({super.key});

  @override
  State<AdminOffersPage> createState() => _AdminOffersPageState();
}

class _AdminOffersPageState extends State<AdminOffersPage> {
  final _api = sl<ApiClient>();
  List<dynamic> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/api/v1/admin/offers');
      if (response.isSuccess && response.data != null) {
        _offers = (response.data!['data']?['offers'] as List? ?? []);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _expireOffer(String offerId) async {
    await _api.patch('/api/v1/admin/offers/$offerId/expire');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offers')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _offers.length,
                itemBuilder: (_, i) {
                  final o = _offers[i] as Map<String, dynamic>;
                  final status = o['status'] as String? ?? '';
                  return ListTile(
                    title: Text(o['title'] as String? ?? ''),
                    subtitle: Text('${o['discountedPrice'] ?? ''} EGP · $status'),
                    trailing: status == 'active'
                        ? IconButton(
                            icon: Icon(Icons.timer_off, color: Theme.of(context).colorScheme.error),
                            onPressed: () => _expireOffer(o['id'] as String),
                          )
                        : null,
                  );
                },
              ),
            ),
    );
  }
}
