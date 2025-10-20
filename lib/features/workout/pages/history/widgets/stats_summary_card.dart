// lib/features/workout/pages/history/widgets/stats_summary_card.dart
import 'package:flutter/material.dart';
import 'stat_item.dart';

class StatsSummaryCard extends StatelessWidget {
  final List<({DateTime day, int volume})> volumes;

  const StatsSummaryCard({super.key, required this.volumes});

  @override
  Widget build(BuildContext context) {
    final totalSeries = volumes.fold<int>(0, (sum, v) => sum + v.volume);
    final maxVol = volumes.isEmpty
        ? 0
        : volumes.map((v) => v.volume).reduce((a, b) => a > b ? a : b);
    final avgVol = volumes.isEmpty ? 0.0 : totalSeries / volumes.length;
    final daysWithWorkout = volumes.where((v) => v.volume > 0).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Resumo do Período',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: StatItem(
                    icon: Icons.format_list_numbered,
                    label: 'Total de Séries',
                    value: '$totalSeries',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatItem(
                    icon: Icons.trending_up,
                    label: 'Máximo por Dia',
                    value: '$maxVol',
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatItem(
                    icon: Icons.show_chart,
                    label: 'Média por Dia',
                    value: avgVol.toStringAsFixed(1),
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatItem(
                    icon: Icons.calendar_today,
                    label: 'Dias com Treino',
                    value: '$daysWithWorkout',
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}