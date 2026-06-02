import 'package:flutter/material.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

class AdminReferralsPage extends StatefulWidget {
  const AdminReferralsPage({super.key});

  @override
  State<AdminReferralsPage> createState() => _AdminReferralsPageState();
}

class _AdminReferralsPageState extends State<AdminReferralsPage> {
  final _api = sl<ApiClient>();
  List<dynamic> _referrals = [];
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
      final [refRes, statsRes] = await Future.wait([
        _api.get('/api/v1/admin/referrals'),
        _api.get('/api/v1/admin/referrals/stats'),
      ]);
      if (refRes.isSuccess && refRes.data != null) {
        _referrals = (refRes.data!['referrals'] as List? ?? []);
      }
      if (statsRes.isSuccess && statsRes.data != null) {
        _stats = statsRes.data;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Referrals')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  if (_stats != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Referral Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              _statRow('Total Referrals', '${_stats!['totalReferrals'] ?? 0}'),
                              _statRow('Rewarded', '${_stats!['rewardedCount'] ?? 0}'),
                              _statRow('Total Rewards', '${_stats!['totalRewardAmount'] ?? 0} EGP'),
                              _statRow('Pending', '${_stats!['pendingCount'] ?? 0}'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_referrals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: Text('No referrals yet')),
                    )
                  else
                    ...(_referrals.map((r) {
                      final ref = r as Map<String, dynamic>;
                      final referrer = ref['referrer'] as Map<String, dynamic>? ?? {};
                      final referee = ref['referee'] as Map<String, dynamic>? ?? {};
                      return ListTile(
                        title: Text('${referrer['email'] ?? '?'} → ${referee['email'] ?? '?'}'),
                        subtitle: Text('Status: ${ref['status'] ?? 'pending'}'),
                        trailing: ref['rewardAmount'] != null
                            ? Text('${ref['rewardAmount']} EGP')
                            : null,
                      );
                    }).toList()),
                ],
              ),
            ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
