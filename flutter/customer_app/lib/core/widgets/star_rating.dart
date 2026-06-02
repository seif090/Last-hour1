import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int count;
  final double size;

  const StarRating({super.key, this.rating = 0, this.count = 0, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final filled = i < rating.floor();
          final half = !filled && i == rating.floor() && rating - i >= 0.5;
          return Icon(
            filled ? Icons.star : half ? Icons.star_half : Icons.star_border,
            size: size,
            color: Colors.amber,
          );
        }),
        if (count > 0) ...[
          const SizedBox(width: 4),
          Text('($count)', style: TextStyle(fontSize: size - 2, color: Colors.grey.shade600)),
        ],
      ],
    );
  }
}
