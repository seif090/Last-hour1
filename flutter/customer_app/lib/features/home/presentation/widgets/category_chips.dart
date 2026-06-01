import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  static const categories = {
    'all': 'All',
    'bakery': 'Bakery',
    'meal': 'Meals',
    'dessert': 'Desserts',
    'beverage': 'Drinks',
    'groceries': 'Groceries',
    'other': 'Other',
  };

  const CategoryChips({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final key = categories.keys.elementAt(index);
          final label = categories.values.elementAt(index);
          final isSelected = selected == key;
          return ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onSelected(key),
          );
        },
      ),
    );
  }
}
