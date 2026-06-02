import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lasthour_shared/models/user.dart';
import '../bloc/profile_bloc.dart';
import '../../../../services/api_client.dart';
import '../../../../injector.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileBloc _bloc;
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bloc = ProfileBloc(api: sl<ApiClient>());
    _bloc.add(LoadProfile());
  }

  @override
  void dispose() {
    _bloc.close();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading && state is! ProfileLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProfileError && state is! ProfileLoaded) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => _bloc.add(LoadProfile()), child: const Text('Retry')),
                  ],
                ),
              );
            }
            if (state is ProfileLoaded || state is ProfileUpdateSuccess) {
              final user = state is ProfileLoaded ? state.user : (state as ProfileUpdateSuccess).user;
              if (_phoneController.text.isEmpty && user.phone != null) {
                _phoneController.text = user.phone!;
              }
              return _buildProfileContent(context, user);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, User user) {
    final theme = Theme.of(context);
    final displayName = user.email.split('@').first;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              displayName[0].toUpperCase(),
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 16),
          Text(displayName, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          Text(user.email, style: TextStyle(fontSize: 13, color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: user.role == 'merchant' ? theme.colorScheme.secondary : theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(user.role.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: user.role == 'merchant' ? theme.colorScheme.secondary : theme.colorScheme.primary)),
          ),
          const SizedBox(height: 32),
          _buildInfoTile(Icons.phone, 'Phone', _phoneController.text.isNotEmpty ? _phoneController.text : 'Not set'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update Phone', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      hintText: 'Enter phone number',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _bloc.add(UpdateProfile(phone: _phoneController.text));
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('My Orders'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/orders'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.location_on_outlined),
              title: const Text('My Addresses'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/addresses'),
            ),
          ),
          if (user.role == 'merchant')
            Card(
              child: ListTile(
                leading: const Icon(Icons.store),
                title: const Text('Merchant Dashboard'),
                subtitle: const Text('Switch to merchant app'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            ),
          if (user.role != 'merchant') ...[
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: const Text('Sell on Last Hour'),
                subtitle: const Text('Register as a merchant'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showMerchantRegistration(context),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Saved Offers'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/favorites'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.credit_card_outlined),
              title: const Text('Payment Methods'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/payment-methods'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/notification-preferences'),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Refer a Friend'),
              subtitle: const Text('Share your referral code'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showReferral(context),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.logout, color: theme.colorScheme.error),
              label: Text('Logout', style: TextStyle(color: theme.colorScheme.error)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: theme.colorScheme.error)),
              onPressed: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        subtitle: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showMerchantRegistration(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Become a Merchant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text('Register your business on Last Hour and start selling to customers near you.'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/merchant/register');
                },
                child: const Text('Register Now'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showReferral(BuildContext context) async {
    final theme = Theme.of(context);
    final api = sl<ApiClient>();
    final response = await api.get('/api/v1/referrals/info');
    if (response.isSuccess && response.data != null) {
      final code = response.data!['referralCode'] as String? ?? '';
      final total = response.data!['totalReferrals'] as int? ?? 0;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Refer a Friend'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.share, size: 48, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text('Your referral code:', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
              ),
              const SizedBox(height: 16),
              Text('$total friends referred so far'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Copy to clipboard
              },
              child: const Text('Copy Code'),
            ),
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    }
  }
}
