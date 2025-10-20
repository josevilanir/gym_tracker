// lib/features/workout/pages/history/widgets/quick_filters.dart
import 'package:flutter/material.dart';

// Enum movido para cá para evitar dependência circular
enum QuickRange { last7, last30, thisMonth, all, custom }

class QuickFilters extends StatelessWidget {
  final QuickRange current;
  final ValueChanged<QuickRange> onSelected;

  const QuickFilters({
    super.key,
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (label: '7 dias', value: QuickRange.last7),
      (label: 'Intervalo…', value: QuickRange.custom),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: items.map((e) {
          final selected = e.value == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.label),
              selected: selected,
              onSelected: (_) => onSelected(e.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}