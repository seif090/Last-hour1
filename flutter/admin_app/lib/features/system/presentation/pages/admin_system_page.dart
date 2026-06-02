import 'package:flutter/material.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

class AdminSystemPage extends StatefulWidget {
  const AdminSystemPage({super.key});

  @override
  State<AdminSystemPage> createState() => _AdminSystemPageState();
}

class _AdminSystemPageState extends State<AdminSystemPage> {
  final _api = sl<ApiClient>();
  Map<String, dynamic>? _health;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/api/v1/admin/system/health');
      if (response.isSuccess && response.data != null) {
        setState(() => _health = response.data!['data'] as Map<String, dynamic>? ?? response.data);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('System Health')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _healthTile('DB Latency', '${_health?['dbLatencyMs'] ?? "—"} ms'),
                  _healthTile('Cache Latency', '${_health?['cacheLatencyMs'] ?? "—"} ms'),
                  _healthTile('Memory Usage', '${_health?['memoryUsageMb'] ?? "—"} MB'),
                  _healthTile('CPU Load', '${_health?['cpuLoad'] ?? "—"}'),
                  _healthTile('Uptime', '${_health?['uptime'] ?? "—"}'),
                ],
              ),
            ),
    );
  }

  Widget _healthTile(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
