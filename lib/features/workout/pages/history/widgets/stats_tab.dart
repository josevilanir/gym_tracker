// lib/features/workout/pages/history/widgets/stats_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../controllers/providers.dart';
import 'volume_chart_card.dart';
import 'stats_summary_card.dart';

class StatsTab extends ConsumerWidget {
  final (DateTime, DateTime) Function() currentBounds;

  const StatsTab({
    super.key,
    required this.currentBounds,
  });

  Future<List<({DateTime day, int volume})>> _loadDailyVolume(WidgetRef ref) async {
    final repo = ref.read(workoutRepoProvider);
    final (start, end) = currentBounds();

    final startDay = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);

    final workouts = await repo.listFinishedWorkoutsBetween(
      start: startDay,
      end: DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59),
    );

    final Map<DateTime, int> perDay = {};
    for (final w in workouts) {
      final d = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
      final key = DateTime(d.year, d.month, d.day);
      final sets = await repo.countSetsInWorkout(w.id);
      perDay.update(key, (old) => old + sets, ifAbsent: () => sets);
    }

    final totalDays = endDay.difference(startDay).inDays + 1;
    return List.generate(totalDays, (i) {
      final d = DateTime(startDay.year, startDay.month, startDay.day + i);
      final key = DateTime(d.year, d.month, d.day);
      return (day: d, volume: perDay[key] ?? 0);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<({DateTime day, int volume})>>(
      future: _loadDailyVolume(ref),
      builder: (context, vSnap) {
        if (vSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (vSnap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar dados',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${vSnap.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      (context as Element).markNeedsBuild();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        final volumes = vSnap.data ?? const <({DateTime day, int volume})>[];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            VolumeChartCard(volumes: volumes),
            const SizedBox(height: 16),
            StatsSummaryCard(volumes: volumes),
          ],
        );
      },
    );
  }
}