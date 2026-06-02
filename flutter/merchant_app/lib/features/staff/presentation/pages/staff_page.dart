import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/staff_bloc.dart';
import '../../../services/api_client.dart';
import '../../../injector.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  late final StaffBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = StaffBloc(api: sl<ApiClient>())..add(LoadStaff());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showInviteSheet(context),
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<StaffBloc, StaffState>(
          builder: (context, state) {
            if (state is StaffLoading || state is StaffInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is StaffError) {
              return Center(child: Text(state.message));
            }
            if (state is StaffLoaded) {
              if (state.members.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No staff members', style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.person_add),
                        label: const Text('Invite Staff'),
                        onPressed: () => _showInviteSheet(context),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _bloc.add(LoadStaff()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.members.length,
                  itemBuilder: (_, i) {
                    final m = state.members[i];
                    final name = m['name'] as String? ?? '';
                    final email = m['email'] as String? ?? '';
                    final role = m['role'] as String? ?? 'staff';
                    final isActive = m['isActive'] == true || m['is_active'] == true;
                    final invitedAt = m['invitedAt'] as String? ?? m['invited_at'] as String? ?? '';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                              child: Icon(Icons.person, color: isActive ? Colors.green : Colors.grey),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                  Row(
                                    children: [
                                      _roleChip(role),
                                      const SizedBox(width: 8),
                                      Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.red.shade300)),
                                      if (invitedAt.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text('Invited: ${invitedAt.substring(0, 10)}', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuButton<String>(
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'toggle', child: Text(isActive ? 'Deactivate' : 'Activate')),
                                const PopupMenuItem(value: 'delete', child: Text('Remove', style: TextStyle(color: Colors.red))),
                              ],
                              onSelected: (action) {
                                if (action == 'toggle') {
                                  _bloc.add(ToggleStaffActive(m['id'] as String, !isActive));
                                } else if (action == 'delete') {
                                  _confirmRemove(m['id'] as String, name);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _roleChip(String role) {
    Color color;
    switch (role) {
      case 'admin': color = Colors.purple; break;
      case 'manager': color = Colors.blue; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(role[0].toUpperCase() + role.substring(1), style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _confirmRemove(String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Staff'),
        content: Text('Remove $name from staff?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _bloc.add(RemoveStaff(id)); },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showInviteSheet(BuildContext context) {
    final emailCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    String role = 'staff';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Invite Staff', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                ],
                onChanged: (v) => setSheetState(() => role = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty) return;
                  _bloc.add(InviteStaff(emailCtrl.text.trim(), nameCtrl.text.trim(), role));
                  Navigator.pop(ctx);
                },
                child: const Text('Send Invite'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
