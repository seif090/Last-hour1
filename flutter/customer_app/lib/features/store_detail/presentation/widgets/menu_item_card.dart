import 'package:flutter/material.dart';

class MenuItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onTap;

  const MenuItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = item['name'] as String? ?? '';
    final description = item['description'] as String?;
    final originalPrice = (item['original_price'] as num?)?.toDouble() ?? 0;
    final category = item['category'] as String?;
    final unit = item['unit'] as String? ?? 'piece';
    final imageUrls = item['image_urls'] as List<dynamic>?;
    final imageUrl = imageUrls != null && imageUrls.isNotEmpty ? imageUrls.first as String? : null;
    final offers = item['offers'] as List<dynamic>?;
    final hasActiveOffer = offers != null && offers.any((o) {
      final oMap = o as Map<String, dynamic>;
      return oMap['status'] == 'active';
    });
    final discountedPrice = hasActiveOffer
        ? (offers!.firstWhere((o) => (o as Map<String, dynamic>)['status'] == 'active')
            as Map<String, dynamic>)['discounted_price'] as num?
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: hasActiveOffer ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(imageUrl, width: 72, height: 72, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderIcon()),
                )
              else
                _placeholderIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (category != null)
                      Text(category, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    if (description != null) ...[
                      const SizedBox(height: 2),
                      Text(description, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                    const SizedBox(height: 4),
                    if (hasActiveOffer && discountedPrice != null)
                      Row(
                        children: [
                          Text('$discountedPrice EGP',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary)),
                          const SizedBox(width: 6),
                          Text('$originalPrice EGP',
                              style: const TextStyle(fontSize: 12, color: Colors.grey,
                                  decoration: TextDecoration.lineThrough)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Deal!', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      )
                    else
                      Text('$originalPrice EGP / $unit',
                          style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
                  ],
                ),
              ),
              if (hasActiveOffer)
                Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 72, height: 72,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood, color: Colors.grey),
    );
  }
}
