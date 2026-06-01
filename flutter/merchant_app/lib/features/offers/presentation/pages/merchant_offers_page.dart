import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/merchant_offers_bloc.dart';
import '../widgets/merchant_offer_tile.dart';
import '../../../services/api_client.dart';

class MerchantOffersPage extends StatefulWidget {
  const MerchantOffersPage({super.key});

  @override
  State<MerchantOffersPage> createState() => _MerchantOffersPageState();
}

class _MerchantOffersPageState extends State<MerchantOffersPage> {
  late final MerchantOffersBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = MerchantOffersBloc(api: ApiClient(baseUrl: 'http://localhost:3000'));
    _bloc.add(const LoadMerchantOffers());
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
        title: const Text('My Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSheet(context),
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocConsumer<MerchantOffersBloc, MerchantOffersState>(
          listener: (ctx, state) {
            if (state is MerchantOffersError) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message)));
            }
            if (state is OfferActionSuccess) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is MerchantOffersLoading && state is! MerchantOffersLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MerchantOffersLoaded) {
              if (state.offers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No offers yet', style: TextStyle(color: Colors.grey.shade500)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _bloc.add(const LoadMerchantOffers()),
                child: ListView.builder(
                  itemCount: state.offers.length,
                  itemBuilder: (_, i) => MerchantOfferTile(
                    offer: state.offers[i],
                    onTap: () => _showOfferDetail(context, state.offers[i]),
                  ),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  void _showCreateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CreateOfferSheet(bloc: _bloc),
    );
  }

  void _showOfferDetail(BuildContext context, dynamic offer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(offer.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock: ${offer.stockRemaining}/${offer.stockInitial}'),
            const SizedBox(height: 8),
            Text('Price: ${offer.discountedPrice.toStringAsFixed(0)} EGP'),
            const SizedBox(height: 8),
            Text('Ends: ${offer.endTime.toString().substring(0, 16)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _bloc.add(EndOffer(offer.id));
              Navigator.pop(ctx);
            },
            child: const Text('End Now', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              _bloc.add(DeleteOffer(offer.id));
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              _showStockDialog(ctx, offer);
            },
            child: const Text('Update Stock'),
          ),
        ],
      ),
    );
  }

  void _showStockDialog(BuildContext context, dynamic offer) {
    final ctrl = TextEditingController(text: '${offer.stockRemaining}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Stock'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stock'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final stock = int.tryParse(ctrl.text);
              if (stock != null) {
                _bloc.add(UpdateStock(offer.id, stock));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

class _CreateOfferSheet extends StatefulWidget {
  final MerchantOffersBloc bloc;
  const _CreateOfferSheet({required this.bloc});

  @override
  State<_CreateOfferSheet> createState() => _CreateOfferSheetState();
}

class _CreateOfferSheetState extends State<_CreateOfferSheet> {
  final _formKey = GlobalKey<FormState>();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController(text: '50');
  final _maxCtrl = TextEditingController(text: '5');
  String? _productId;

  @override
  void initState() {
    super.initState();
    widget.bloc.add(const LoadProducts());
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24, right: 24, top: 24,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Create Offer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            BlocBuilder<MerchantOffersBloc, MerchantOffersState>(
              builder: (context, state) {
                if (state is MerchantOffersLoaded && state.products.isNotEmpty) {
                  return DropdownButtonFormField<String>(
                    value: _productId,
                    decoration: const InputDecoration(labelText: 'Product', border: OutlineInputBorder()),
                    items: state.products.map((p) => DropdownMenuItem(
                      value: p['id'],
                      child: Text(p['name'] as String),
                    )).toList(),
                    onChanged: (v) => _productId = v,
                    validator: (v) => v == null ? 'Select a product' : null,
                  );
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Discounted Price (EGP)', border: OutlineInputBorder()),
              validator: (v) => v != null && double.tryParse(v) != null ? null : 'Valid price required',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _maxCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max per customer', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                widget.bloc.add(CreateOffer({
                  'product_id': _productId,
                  'discounted_price': double.parse(_priceCtrl.text),
                  'stock_initial': int.parse(_stockCtrl.text),
                  'max_per_customer': int.parse(_maxCtrl.text),
                }));
                Navigator.pop(context);
              },
              child: const Text('Create Offer'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
