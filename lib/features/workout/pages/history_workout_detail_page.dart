import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/providers.dart';
import '../../../data/db/app_database.dart';

class HistoryWorkoutDetailPage extends ConsumerWidget {
  final String workoutId;
  const HistoryWorkoutDetailPage({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);

    return FutureBuilder<Workout?>(
      future: repo.getWorkout(workoutId),
      builder: (context, snapW) {
        final w = snapW.data;
        final title = (w?.title?.trim().isNotEmpty ?? false) ? w!.title! : 'Treino';

        return Scaffold(
          appBar: AppBar(
            title: Text('Detalhes • $title'),
          ),
          body: snapW.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : (w == null)
                  ? const Center(child: Text('Treino não encontrado.'))
                  : _ReadOnlyBody(workout: w),
        );
      },
    );
  }
}

class _ReadOnlyBody extends ConsumerWidget {
  final Workout workout;
  const _ReadOnlyBody({required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);
    final date = DateTime.fromMillisecondsSinceEpoch(workout.dateEpoch);
    final dateStr = DateFormat('dd/MM/yyyy – HH:mm').format(date);

    return FutureBuilder<List<WorkoutExercise>>(
      future: repo.listWorkoutExercises(workout.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final exercises = snap.data ?? const <WorkoutExercise>[];

        if (exercises.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Sem exercícios registrados'),
                  subtitle: Text('Treino concluído em $dateStr'),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: Text((workout.title?.trim().isNotEmpty ?? false)
                    ? workout.title!.trim()
                    : 'Treino concluído'),
                subtitle: Text('Concluído em $dateStr'),
              ),
            ),
            const SizedBox(height: 12),
            ...exercises.map((we) => _ReadOnlyExerciseTile(we: we)).toList(),
          ],
        );
      },
    );
  }
}

class _ReadOnlyExerciseTile extends ConsumerWidget {
  final WorkoutExercise we;
  const _ReadOnlyExerciseTile({required this.we});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);

    return FutureBuilder<Exercise?>(
      future: repo.getExercise(we.exerciseId),
      builder: (context, exSnap) {
        final ex = exSnap.data;

        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.fitness_center),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ex?.name ?? 'Exercício',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (we.done) const Icon(Icons.check, color: Colors.green),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<SetEntry>>(
                  future: repo.listSets(we.id),
                  builder: (context, setsSnap) {
                    final sets = setsSnap.data ?? const <SetEntry>[];

                    if (sets.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: 8.0, left: 4),
                        child: Text('Sem séries registradas'),
                      );
                    }

                    return Column(
                      children: sets
                          .map(
                            (s) => ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                              leading: CircleAvatar(
                                radius: 14,
                                child: Text('${s.setIndex}'),
                              ),
                              title: Text('Reps: ${s.reps}'),
                              subtitle: Text('Peso: ${s.weight.toStringAsFixed(1)} kg'),
                              // ❌ sem ações: somente leitura
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
