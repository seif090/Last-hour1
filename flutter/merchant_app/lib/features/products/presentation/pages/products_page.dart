import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../services/api_client.dart';
import '../../../../injector.dart';
import '../bloc/products_bloc.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final ProductsBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = ProductsBloc(api: sl<ApiClient>());
    _bloc.add(LoadProducts());
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
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showProductDialog(context),
          ),
        ],
      ),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocConsumer<ProductsBloc, ProductsState>(
          listener: (context, state) {
            if (state is ProductOperationSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
            if (state is ProductsError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is ProductsLoading && state is! ProductsLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is ProductsLoaded) {
              if (state.products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No products yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showProductDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Product'),
                      ),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _bloc.add(LoadProducts()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.products.length,
                  itemBuilder: (_, i) => _buildProductCard(context, state.products[i]),
                ),
              );
            }
            if (state is ProductsError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(state.message, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: () => _bloc.add(LoadProducts()), child: const Text('Retry')),
                  ],
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> product) {
    final name = product['name'] as String? ?? '';
    final price = (product['original_price'] as num?)?.toDouble() ?? 0;
    final category = product['category'] as String?;
    final isActive = product['is_active'] as bool? ?? true;
    final imageUrls = product['image_urls'] as List<dynamic>?;
    final imageUrl = imageUrls != null && imageUrls.isNotEmpty ? imageUrls.first as String? : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.inventory_2, color: Colors.grey.shade400)),
              )
            : CircleAvatar(child: Icon(Icons.inventory_2, color: Colors.grey.shade400)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$price EGP${category != null ? ' • $category' : ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Inactive', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') _showProductDialog(context, product: product);
                if (value == 'delete') _confirmDelete(context, product['id'] as String, name);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDialog(BuildContext context, {Map<String, dynamic>? product}) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?['name'] as String? ?? '');
    final priceCtrl = TextEditingController(text: product?['original_price']?.toString() ?? '');
    final descCtrl = TextEditingController(text: product?['description'] as String? ?? '');
    final categoryCtrl = TextEditingController(text: product?['category'] as String? ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16, right: 16, top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? 'Edit Product' : 'New Product',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Price (EGP)', border: OutlineInputBorder()), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: categoryCtrl, decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final data = <String, dynamic>{
                      'name': nameCtrl.text,
                      'originalPrice': double.tryParse(priceCtrl.text) ?? 0,
                      'description': descCtrl.text,
                      'category': categoryCtrl.text,
                    };
                    if (isEdit) {
                      _bloc.add(UpdateProduct(product!['id'] as String, data));
                    } else {
                      _bloc.add(CreateProduct(data));
                    }
                    Navigator.pop(ctx);
                  },
                  child: Text(isEdit ? 'Update' : 'Create'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "$name"? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              _bloc.add(DeleteProduct(id));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
