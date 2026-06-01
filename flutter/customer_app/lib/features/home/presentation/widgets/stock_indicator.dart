import 'package:flutter/material.dart';

class StockIndicator extends StatelessWidget {
  final int remaining;
  final int initial;

  const StockIndicator({super.key, required this.remaining, required this.initial});

  @override
  Widget build(BuildContext context) {
    final pct = initial > 0 ? remaining / initial : 0.0;
    Color color;
    if (pct <= 0.1) {
      color = Colors.red;
    } else if (pct <= 0.3) {
      color = Colors.orange;
    } else {
      color = Colors.green;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.inventory_2_outlined, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          '$remaining left',
          style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
