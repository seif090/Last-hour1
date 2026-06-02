import 'package:flutter/material.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

class AdminMerchantsPage extends StatefulWidget {
  const AdminMerchantsPage({super.key});

  @override
  State<AdminMerchantsPage> createState() => _AdminMerchantsPageState();
}

class _AdminMerchantsPageState extends State<AdminMerchantsPage> {
  final _api = sl<ApiClient>();
  List<dynamic> _merchants = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/api/v1/admin/merchants');
      if (response.isSuccess && response.data != null) {
        _merchants = (response.data!['data']?['merchants'] as List? ?? []);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _toggleVerify(String merchantId) async {
    await _api.patch('/api/v1/admin/merchants/$merchantId/verify');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merchants')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _merchants.length,
                itemBuilder: (_, i) {
                  final m = _merchants[i] as Map<String, dynamic>;
                  final verified = m['isVerified'] as bool? ?? false;
                  final business = m['businessName'] as String? ?? '';
                  return ListTile(
                    title: Text(business),
                    subtitle: Text('${m['businessType'] ?? ''} · ${verified ? "Verified" : "Unverified"}'),
                    trailing: IconButton(
                      icon: Icon(verified ? Icons.verified : Icons.verified_outlined,
                          color: verified ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
                      onPressed: () => _toggleVerify(m['id'] as String),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
