import 'package:flutter/material.dart';
import 'package:lasthour_shared/models/offer.dart';

class MerchantOfferTile extends StatelessWidget {
  final Offer offer;
  final VoidCallback? onTap;

  const MerchantOfferTile({super.key, required this.offer, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: offer.isLowStock ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.local_offer,
            color: offer.isLowStock ? Colors.red : Colors.green,
          ),
        ),
        title: Text(offer.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${offer.discountedPrice.toStringAsFixed(0)} EGP — ${offer.stockRemaining}/${offer.stockInitial}'),
        trailing: Text(
          offer.endTime.difference(DateTime.now()).inHours > 0
              ? '${offer.endTime.difference(DateTime.now()).inHours}h left'
              : '${offer.endTime.difference(DateTime.now()).inMinutes}m left',
          style: TextStyle(fontSize: 12, color: offer.isLowStock ? Colors.red : Colors.grey),
        ),
      ),
    );
  }
}
