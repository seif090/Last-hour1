import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/payment_methods_bloc.dart';
import '../../../../services/api_client.dart';
import '../../../../injector.dart';

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});

  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  late final PaymentMethodsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = PaymentMethodsBloc(api: sl<ApiClient>())..add(LoadPaymentMethods());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: () => _showAddSheet(context),
        child: const Icon(Icons.add),
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<PaymentMethodsBloc, PaymentMethodsState>(
          builder: (context, state) {
            if (state is PaymentMethodsLoading || state is PaymentMethodsInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is PaymentMethodsError) {
              return Center(child: Text(state.message));
            }
            if (state is PaymentMethodsLoaded) {
              final methods = state.methods;
              if (methods.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.credit_card_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 16),
                      Text('No saved payment methods', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Add Payment Method'),
                        onPressed: () => _showAddSheet(context),
                      ),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: methods.length,
                itemBuilder: (_, i) {
                  final m = methods[i];
                  final isDefault = m['isDefault'] == true || m['is_default'] == true;
                  final brand = m['brand'] as String? ?? 'Card';
                  final last4 = m['last4'] as String? ?? '****';
                  final expiry = m['expiryMonth'] != null
                      ? '${m['expiryMonth']}/${m['expiryYear']}'
                      : null;
                  return Card(
                    child: ListTile(
                      leading: Icon(
                        brand.toLowerCase().contains('mastercard')
                            ? Icons.credit_card
                            : Icons.credit_card,
                        color: theme.colorScheme.primary,
                        size: 32,
                      ),
                      title: Text('$brand •••• $last4'),
                      subtitle: Text(expiry ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDefault)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.tertiary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('Default', style: TextStyle(fontSize: 11, color: theme.colorScheme.tertiary)),
                            ),
                          if (!isDefault && methods.length > 1)
                            IconButton(
                              icon: const Icon(Icons.star_outline, size: 18),
                              tooltip: 'Set as default',
                              onPressed: () => _bloc.add(SetDefaultPaymentMethod(m['id'] as String)),
                            ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 18, color: theme.colorScheme.error),
                            onPressed: () => _confirmDelete(m['id'] as String),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: const Text('Are you sure you want to remove this payment method?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(DeletePaymentMethod(id));
            },
            child: Text('Remove', style: TextStyle(color: theme.colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final brandCtrl = TextEditingController();
    final last4Ctrl = TextEditingController();
    final monthCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    String provider = 'stripe';

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Add Payment Method', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Card Brand', hintText: 'Visa', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: last4Ctrl, maxLength: 4, decoration: const InputDecoration(labelText: 'Last 4 Digits', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(controller: monthCtrl, decoration: const InputDecoration(labelText: 'Expiry Month', hintText: '12', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Expiry Year', hintText: '2028', border: OutlineInputBorder()), keyboardType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: provider,
                decoration: const InputDecoration(labelText: 'Provider', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'stripe', child: Text('Stripe')),
                  DropdownMenuItem(value: 'paymob', child: Text('Paymob')),
                ],
                onChanged: (v) => setSheetState(() => provider = v!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (brandCtrl.text.trim().isEmpty || last4Ctrl.text.trim().isEmpty) return;
                  _bloc.add(AddPaymentMethod({
                    'provider': provider,
                    'paymentMethodId': 'manual_${DateTime.now().millisecondsSinceEpoch}',
                    'last4': last4Ctrl.text.trim(),
                    'brand': brandCtrl.text.trim(),
                    'expiryMonth': int.tryParse(monthCtrl.text.trim()),
                    'expiryYear': int.tryParse(yearCtrl.text.trim()),
                    'isDefault': false,
                  }));
                  Navigator.pop(ctx);
                },
                child: const Text('Add Card'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
