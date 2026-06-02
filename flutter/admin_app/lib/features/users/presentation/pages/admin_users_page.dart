import 'package:flutter/material.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _api = sl<ApiClient>();
  List<dynamic> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _api.get('/api/v1/admin/users');
      if (response.isSuccess && response.data != null) {
        _users = (response.data!['data']?['users'] as List? ?? []);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _toggleBan(String userId, bool banned) async {
    await _api.patch('/api/v1/admin/users/$userId/ban');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Users')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _users.length,
                itemBuilder: (_, i) {
                  final u = _users[i] as Map<String, dynamic>;
                  final isActive = u['isActive'] as bool? ?? true;
                  return ListTile(
                    title: Text(u['email'] as String? ?? ''),
                    subtitle: Text('Role: ${u['role'] ?? ''}'),
                    trailing: IconButton(
                      icon: Icon(isActive ? Icons.block : Icons.check_circle,
                          color: isActive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.tertiary),
                      onPressed: () => _toggleBan(u['id'] as String, isActive),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
