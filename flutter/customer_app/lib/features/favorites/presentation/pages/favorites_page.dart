import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../services/api_client.dart';
import '../../../../injector.dart';
import '../bloc/favorites_bloc.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late final FavoritesBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = FavoritesBloc(api: sl<ApiClient>());
    _bloc.add(LoadFavorites());
  }

  @override
  void dispose() {
    _bloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Offers')),
      body: BlocProvider.value(
        value: _bloc,
        child: BlocConsumer<FavoritesBloc, FavoritesState>(
          listener: (context, state) {
            if (state is FavoritesError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            if (state is FavoritesLoading && state is! FavoritesLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is FavoritesLoaded) {
              if (state.favorites.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('No saved offers yet', style: TextStyle(fontSize: 16, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Text('Tap the heart icon on offers to save them', style: TextStyle(color: Colors.grey.shade400)),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async => _bloc.add(LoadFavorites()),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: state.favorites.length,
                  itemBuilder: (_, i) => _buildFavCard(context, state.favorites[i]),
                ),
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildFavCard(BuildContext context, Map<String, dynamic> fav) {
    final offer = fav['offer'] as Map<String, dynamic>? ?? fav;
    final store = offer['store'] as Map<String, dynamic>?;
    final title = offer['title'] as String? ?? '';
    final price = (offer['discounted_price'] as num?)?.toDouble() ?? 0;
    final imageUrl = offer['image_url'] as String?;
    final storeName = store?['name'] as String? ?? '';
    final storeId = store?['id'] as String? ?? '';
    final offerId = offer['id'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, width: 48, height: 48, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.local_offer, color: Colors.grey.shade400)),
              )
            : CircleAvatar(child: Icon(Icons.local_offer, color: Colors.grey.shade400)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$price EGP${storeName.isNotEmpty ? ' • $storeName' : ''}'),
        trailing: IconButton(
          icon: const Icon(Icons.favorite, color: Colors.red),
          onPressed: () => _bloc.add(RemoveFavorite(offerId)),
        ),
        onTap: () => context.go('/offers/$offerId'),
      ),
    );
  }
}
