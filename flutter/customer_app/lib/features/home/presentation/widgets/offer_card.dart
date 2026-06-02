import 'package:flutter/material.dart';
import 'package:lasthour_shared/models/offer.dart';
import 'stock_indicator.dart';
import 'offer_timer.dart';

class OfferCard extends StatelessWidget {
  final Offer offer;
  final VoidCallback? onTap;
  final VoidCallback? onStoreTap;
  final bool isFavorited;
  final VoidCallback? onFavoriteToggle;

  const OfferCard({super.key, required this.offer, this.onTap, this.onStoreTap, this.isFavorited = false, this.onFavoriteToggle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImageHeader(context),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: onStoreTap,
                          child: Text(
                            offer.storeName,
                            style: TextStyle(fontSize: 13, color: theme.colorScheme.primary, decoration: TextDecoration.underline),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OfferTimer(endTime: offer.endTime),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    offer.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${offer.discountedPrice.toStringAsFixed(0)} EGP',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${offer.originalPrice.toStringAsFixed(0)} EGP',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${offer.discountPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      StockIndicator(remaining: offer.stockRemaining, initial: offer.stockInitial),
                    ],
                  ),
                  if (offer.distanceM > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          offer.distanceM < 1000
                              ? '${offer.distanceM.toStringAsFixed(0)} m'
                              : '${(offer.distanceM / 1000).toStringAsFixed(1)} km',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                        const SizedBox(width: 4),
                        Text(
                          '${offer.ratingAvg.toStringAsFixed(1)} (${offer.ratingCount})',
                          style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(BuildContext context) {
    final theme = Theme.of(context);
    if (offer.imageUrl == null) {
      return _buildFallbackHeader(theme);
    }
    return Stack(
      children: [
        Image.network(
          offer.imageUrl!,
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackHeader(theme),
        ),
        if (offer.isLowStock)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Low stock',
                style: TextStyle(color: theme.colorScheme.onError, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? theme.colorScheme.error : theme.colorScheme.onSurface,
              shadows: [Shadow(color: theme.colorScheme.inverseSurface.withValues(alpha: 0.5), blurRadius: 4)],
            ),
            onPressed: onFavoriteToggle,
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackHeader(ThemeData theme) {
    return Container(
      height: 120,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      child: Stack(
        children: [
          Center(child: Icon(Icons.restaurant, size: 40, color: theme.colorScheme.onSurfaceVariant)),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
              ),
              onPressed: onFavoriteToggle,
            ),
          ),
        ],
      ),
    );
  }
}
