import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../controllers/providers.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/workout_repository.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Filtrar por período',
            icon: const Icon(Icons.filter_alt),
            onPressed: () async {
              final now = DateTime.now();
              final lastWeek = now.subtract(const Duration(days: 7));
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 1),
                initialDateRange: _range ?? DateTimeRange(start: lastWeek, end: now),
              );
              if (picked != null) setState(() => _range = picked);
            },
          ),
          if (_range != null)
            IconButton(
              tooltip: 'Limpar filtro',
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _range = null),
            ),
        ],
      ),
      body: FutureBuilder<List<Workout>>(
        future: repo.listWorkouts(),
        builder: (context, snapshot) {
          var items = snapshot.data ?? [];
          if (_range != null) {
            items = items.where((w) {
              final d = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
              return !d.isBefore(_range!.start) && !d.isAfter(_range!.end);
            }).toList();
          }
          if (items.isEmpty) {
            return const Center(child: Text('Nenhum treino no período.'));
          }

          return FutureBuilder<List<_WorkoutWithVolume>>(
            future: _withVolumes(repo, items),
            builder: (context, snap) {
              final list = snap.data ?? [];
              final f = DateFormat('dd/MM/yyyy HH:mm');
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final it = list[i];
                  final d = DateTime.fromMillisecondsSinceEpoch(it.workout.dateEpoch);
                  return Card(
                    child: ListTile(
                      title: Text(it.workout.title ?? 'Treino ${i + 1}'),
                      subtitle: Text('${f.format(d)} • Volume: ${it.volume.toStringAsFixed(1)} kg'),
                      trailing: Icon(it.workout.done ? Icons.check_circle : Icons.schedule),
                      // ✅ abre a rota unificada
                      onTap: () => context.pushNamed('workout_detail', pathParameters: {'id': it.workout.id}),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<_WorkoutWithVolume>> _withVolumes(
    WorkoutRepository repo,
    List<Workout> workouts,
  ) async {
    final out = <_WorkoutWithVolume>[];
    for (final w in workouts) {
      final vol = await repo.computeWorkoutVolume(w.id);
      out.add(_WorkoutWithVolume(w, vol));
    }
    return out;
  }
}

class _WorkoutWithVolume {
  final Workout workout;
  final double volume;
  _WorkoutWithVolume(this.workout, this.volume);
}
