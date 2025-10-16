import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/providers.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/workout_repository.dart';

/// Fórmula padrão de 1RM usada nas exibições
const _kFormula = OneRmFormula.epley;

/// Tolerância para empates de 1RM (diferenças insignificantes)
const _epsCompare = 0.05;

/// Formata valores de peso com 1 casa decimal
String _fmtKg(double v) => '${v.toStringAsFixed(1)} kg';

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
        final title = (w?.title?.trim().isNotEmpty ?? false)
            ? w!.title!
            : 'Treino';

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
                title: Text(
                  (workout.title?.trim().isNotEmpty ?? false)
                      ? workout.title!.trim()
                      : 'Treino concluído',
                ),
                subtitle: Text('Concluído em $dateStr'),
              ),
            ),
            const SizedBox(height: 12),
            ...exercises
                .map((we) => _ReadOnlyExerciseTile(
                      we: we,
                      workoutId: workout.id,
                    ))
                .toList(),
          ],
        );
      },
    );
  }
}

class _ReadOnlyExerciseTile extends ConsumerWidget {
  final WorkoutExercise we;
  final String workoutId;
  const _ReadOnlyExerciseTile({required this.we, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);
    final scheme = Theme.of(context).colorScheme;

    return FutureBuilder<Exercise?>(
      future: repo.getExercise(we.exerciseId),
      builder: (context, exSnap) {
        final ex = exSnap.data;

        return FutureBuilder<({double? bestInWorkout, double? bestAllTime})>(
          future: bestsForExercise(
            db: repo.db,
            workoutId: workoutId,
            exerciseId: we.exerciseId,
            formula: _kFormula,
          ),
          builder: (context, bestSnap) {
            final bests = bestSnap.data;

            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho
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
                        if (we.done)
                          const Icon(Icons.check, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Chips com melhores 1RM
                    if (bests != null &&
                        (bests.bestInWorkout != null ||
                            bests.bestAllTime != null))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (bests.bestInWorkout != null)
                              Chip(
                                avatar: const Icon(Icons.emoji_events),
                                label: Text(
                                  'Melhor e1RM (treino): ${_fmtKg(bests.bestInWorkout!)}',
                                ),
                                backgroundColor: scheme.surfaceVariant,
                              ),
                            if (bests.bestAllTime != null)
                              Chip(
                                avatar: const Icon(Icons.insights),
                                label: Text(
                                  'PR histórico: ${_fmtKg(bests.bestAllTime!)}',
                                ),
                                backgroundColor: scheme.secondaryContainer,
                                labelStyle: TextStyle(
                                    color: scheme.onSecondaryContainer),
                              ),
                          ],
                        ),
                      ),

                    // Séries com destaque de 1RM
                    FutureBuilder<List<SetEntry>>(
                      future: repo.listSets(we.id),
                      builder: (context, setsSnap) {
                        final sets = setsSnap.data ?? const <SetEntry>[];

                        if (sets.isEmpty) {
                          return const Padding(
                            padding:
                                EdgeInsets.only(bottom: 8.0, left: 4, top: 4),
                            child: Text('Sem séries registradas'),
                          );
                        }

                        double? localBest;
                        final perSetOneRm = <double?>[];

                        for (final s in sets) {
                          final w = s.weight ?? 0;
                          if (w <= 0) {
                            perSetOneRm.add(null);
                            continue;
                          }
                          final oneRm = estimateOneRm(
                            reps: s.reps,
                            weight: w,
                            formula: _kFormula,
                          );
                          perSetOneRm.add(oneRm);
                          if (localBest == null || oneRm > localBest!) {
                            localBest = oneRm;
                          }
                        }

                        int? firstHighlightIndex;
                        if (localBest != null) {
                          for (var i = 0; i < perSetOneRm.length; i++) {
                            final val = perSetOneRm[i];
                            if (val != null &&
                                (localBest! - val).abs() <= _epsCompare) {
                              firstHighlightIndex = i;
                              break;
                            }
                          }
                        }

                        return Column(
                          children: List.generate(sets.length, (i) {
                            final s = sets[i];
                            final e1rm = perSetOneRm[i];
                            final isHighlight = firstHighlightIndex == i;

                            return ListTile(
                              dense: true,
                              visualDensity: VisualDensity.compact,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              leading: CircleAvatar(
                                radius: 14,
                                child: Text('${s.setIndex}'),
                              ),
                              title: Text(
                                  'Reps: ${s.reps}   Peso: ${(s.weight ?? 0).toStringAsFixed(1)} kg'),
                              subtitle: (e1rm == null)
                                  ? const Text('e1RM: —')
                                  : Text(
                                      'e1RM (Epley): ${_fmtKg(e1rm)}',
                                      style: const TextStyle(
                                          fontStyle: FontStyle.italic),
                                    ),
                              trailing: isHighlight
                                  ? Chip(
                                      avatar:
                                          const Icon(Icons.star, size: 16),
                                      label: const Text('Destaque'),
                                      backgroundColor:
                                          scheme.secondaryContainer,
                                      labelStyle: TextStyle(
                                        color: scheme.onSecondaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    )
                                  : null,
                            );
                          }),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
