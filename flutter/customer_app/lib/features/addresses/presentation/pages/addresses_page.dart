import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lasthour_shared/models/address.dart';
import '../bloc/addresses_bloc.dart';
import '../../../../core/widgets/error_screen.dart';
import '../../../../injector.dart';
import '../../../../services/api_client.dart';

class AddressesPage extends StatefulWidget {
  const AddressesPage({super.key});

  @override
  State<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends State<AddressesPage> {
  late final AddressesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = AddressesBloc(api: sl<ApiClient>());
    _bloc.add(const LoadAddresses());
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
        title: const Text('My Addresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddressForm(context),
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocBuilder<AddressesBloc, AddressesState>(
          builder: (context, state) {
            if (state is AddressesLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is AddressesError) {
              return ErrorScreen(
                message: state.message,
                onRetry: () => _bloc.add(const LoadAddresses()),
              );
            }
            if (state is AddressesLoaded) {
              if (state.addresses.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No addresses saved', style: TextStyle(color: Colors.grey.shade500)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showAddressForm(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Address'),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _bloc.add(const LoadAddresses()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.addresses.length,
                  itemBuilder: (_, i) => _buildAddressCard(context, state.addresses[i]),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.location_on, color: address.isDefault ? Colors.red : Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('Default', style: TextStyle(fontSize: 11, color: Colors.red)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(address.addressLine1, style: TextStyle(color: Colors.grey.shade700)),
                  if (address.addressLine2 != null) Text(address.addressLine2!, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  Text('${address.city}${address.district != null ? ', ${address.district}' : ''}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _showAddressForm(context, address: address);
                if (v == 'delete') _confirmDelete(address.id);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddressForm(BuildContext context, {Address? address}) {
    final labelCtrl = TextEditingController(text: address?.label ?? 'Home');
    final line1Ctrl = TextEditingController(text: address?.addressLine1 ?? '');
    final line2Ctrl = TextEditingController(text: address?.addressLine2 ?? '');
    final cityCtrl = TextEditingController(text: address?.city ?? '');
    final districtCtrl = TextEditingController(text: address?.district ?? '');
    final postalCtrl = TextEditingController(text: address?.postalCode ?? '');
    final latCtrl = TextEditingController(text: address?.latitude?.toString() ?? '');
    final lngCtrl = TextEditingController(text: address?.longitude?.toString() ?? '');
    bool isDefault = address?.isDefault ?? false;
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(address != null ? 'Edit Address' : 'Add Address',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: labelCtrl.text,
                  decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Home', child: Text('Home')),
                    DropdownMenuItem(value: 'Work', child: Text('Work')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => labelCtrl.text = v!,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: line1Ctrl,
                  decoration: const InputDecoration(labelText: 'Address Line 1', border: OutlineInputBorder()),
                  validator: (v) => v != null && v.length > 2 ? null : 'Required',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: line2Ctrl,
                  decoration: const InputDecoration(labelText: 'Address Line 2 (optional)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(flex: 2, child: TextFormField(
                      controller: cityCtrl,
                      decoration: const InputDecoration(labelText: 'City', border: OutlineInputBorder()),
                      validator: (v) => v != null && v.length > 1 ? null : 'Required',
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: districtCtrl,
                      decoration: const InputDecoration(labelText: 'District', border: OutlineInputBorder()),
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: TextFormField(
                      controller: postalCtrl,
                      decoration: const InputDecoration(labelText: 'Postal Code', border: OutlineInputBorder()),
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: latCtrl,
                      decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: TextFormField(
                      controller: lngCtrl,
                      decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Set as default address'),
                  value: isDefault,
                  onChanged: (v) => setSheetState(() => isDefault = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final data = <String, dynamic>{
                      'label': labelCtrl.text,
                      'addressLine1': line1Ctrl.text,
                      'addressLine2': line2Ctrl.text.isNotEmpty ? line2Ctrl.text : null,
                      'city': cityCtrl.text,
                      'district': districtCtrl.text.isNotEmpty ? districtCtrl.text : null,
                      'postalCode': postalCtrl.text.isNotEmpty ? postalCtrl.text : null,
                      'latitude': double.tryParse(latCtrl.text),
                      'longitude': double.tryParse(lngCtrl.text),
                      'isDefault': isDefault,
                    };
                    if (address != null) {
                      _bloc.add(UpdateAddress(address.id, data));
                    } else {
                      _bloc.add(CreateAddress(data));
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(address != null ? 'Save Changes' : 'Add Address'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _bloc.add(DeleteAddress(id));
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
