// lib/features/workout/pages/history/widgets/volume_chart_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VolumeChartCard extends StatefulWidget {
  final List<({DateTime day, int volume})> volumes;

  const VolumeChartCard({super.key, required this.volumes});

  @override
  State<VolumeChartCard> createState() => _VolumeChartCardState();
}

class _VolumeChartCardState extends State<VolumeChartCard> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.volumes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Sem dados no período',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final maxVol = widget.volumes.map((v) => v.volume).reduce((a, b) => a > b ? a : b);
    if (maxVol == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              const Text('Nenhum treino registrado no período'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Volume de séries por dia',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(widget.volumes.length, (index) {
                  final v = widget.volumes[index];
                  final heightFactor = maxVol > 0 ? v.volume / maxVol : 0.0;
                  final barHeight = 145 * heightFactor;
                  final isSelected = selectedIndex == index;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedIndex = isSelected ? null : index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: 16,
                              child: isSelected && v.volume > 0
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primaryContainer,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${v.volume}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              fontSize: 11,
                                              height: 1.0,
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                            ),
                                      ),
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              height: barHeight < 6 && v.volume > 0 ? 6 : barHeight,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : v.volume > 0
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.85)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceVariant,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd/MM').format(v.day),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontSize: 9,
                                    height: 1.0,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}