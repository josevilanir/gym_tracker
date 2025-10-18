// lib/features/workout/pages/history_workout_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/providers.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../core/calculations.dart';
import '../../../core/constants.dart';

/// Fórmula padrão de 1RM usada nas exibições
const _kFormula = OneRmFormula.epley;

/// Formata valores de peso com 1 casa decimal
String _fmtKg(double v) => '${v.toStringAsFixed(AppConstants.weightDecimalPlaces)} kg';

class HistoryWorkoutDetailPage extends ConsumerWidget {
  final String workoutId;
  const HistoryWorkoutDetailPage({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);

    // ✅ OTIMIZADO: 1 chamada em vez de N+1
    return FutureBuilder<WorkoutWithDetails>(
      future: repo.getWorkoutWithDetails(workoutId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Carregando...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Erro')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  SizedBox(height: UIConstants.paddingM),
                  Text('Erro ao carregar treino: ${snapshot.error}'),
                  SizedBox(height: UIConstants.paddingL),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Voltar'),
                  ),
                ],
              ),
            ),
          );
        }

        final workoutData = snapshot.data!;
        final workout = workoutData.workout;
        final title = (workout.title?.trim().isNotEmpty ?? false)
            ? workout.title!
            : 'Treino';

        return Scaffold(
          appBar: AppBar(
            title: Text('Detalhes • $title'),
          ),
          body: _ReadOnlyBody(workoutData: workoutData),
        );
      },
    );
  }
}

class _ReadOnlyBody extends ConsumerWidget {
  final WorkoutWithDetails workoutData;
  const _ReadOnlyBody({required this.workoutData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = workoutData.workout;
    final date = DateTime.fromMillisecondsSinceEpoch(workout.dateEpoch);
    final dateStr = DateFormat(AppConstants.dateTimeFormatFull).format(date);

    if (workoutData.exercises.isEmpty) {
      return ListView(
        padding: PaddingConstants.allL,
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
      padding: PaddingConstants.allL,
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(
              (workout.title?.trim().isNotEmpty ?? false)
                  ? workout.title!.trim()
                  : 'Treino concluído',
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Concluído em $dateStr'),
                SizedBox(height: UIConstants.paddingXS),
                Text(
                  '${workoutData.exerciseCount} exercícios • ${workoutData.totalSets} séries • ${_fmtKg(workoutData.totalVolume)} volume',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: UIConstants.paddingM),
        ...workoutData.exercises.map((exData) {
          return _ReadOnlyExerciseTile(
            exData: exData,
            workoutId: workout.id,
          );
        }),
      ],
    );
  }
}

class _ReadOnlyExerciseTile extends ConsumerWidget {
  final WorkoutExerciseWithDetails exData;
  final String workoutId;

  const _ReadOnlyExerciseTile({
    required this.exData,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);
    final scheme = Theme.of(context).colorScheme;
    final ex = exData.exercise;
    final we = exData.workoutExercise;
    final sets = exData.sets;

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
          elevation: UIConstants.elevationM,
          child: Padding(
            padding: PaddingConstants.allM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho do exercício
                Row(
                  children: [
                    const Icon(Icons.fitness_center),
                    SizedBox(width: UIConstants.paddingS),
                    Expanded(
                      child: Text(
                        ex.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (we.done)
                      const Icon(Icons.check, color: Colors.green),
                  ],
                ),
                SizedBox(height: UIConstants.paddingS),

                // Chips com melhores 1RM
                if (bests != null &&
                    (bests.bestInWorkout != null || bests.bestAllTime != null))
                  Padding(
                    padding: EdgeInsets.only(bottom: UIConstants.paddingS),
                    child: Wrap(
                      spacing: UIConstants.paddingS,
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
                              color: scheme.onSecondaryContainer,
                            ),
                          ),
                      ],
                    ),
                  ),

                // ✅ OTIMIZADO: Sets já estão carregados (sem queries extras)
                if (sets.isEmpty)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: UIConstants.paddingS,
                      left: UIConstants.paddingXS,
                      top: UIConstants.paddingXS,
                    ),
                    child: const Text('Sem séries registradas'),
                  )
                else
                  _SetsList(sets: sets, scheme: scheme),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SetsList extends StatelessWidget {
  final List<SetEntry> sets;
  final ColorScheme scheme;

  const _SetsList({
    required this.sets,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular qual série tem o melhor 1RM local
    double? localBest;
    final perSetOneRm = <double?>[];

    for (final s in sets) {
      final w = s.weight;
      if (w <= 0) {
        perSetOneRm.add(null);
        continue;
      }

      final oneRm = estimateOneRm(
        reps: s.reps,
        weight: w,
        formula: OneRmFormula.epley,
      );
      perSetOneRm.add(oneRm);
      if (localBest == null || oneRm > localBest) {
        localBest = oneRm;
      }
    }

    int? firstHighlightIndex;
    if (localBest != null) {
      for (var i = 0; i < perSetOneRm.length; i++) {
        final val = perSetOneRm[i];
        if (val != null &&
            (localBest - val).abs() <= AppConstants.oneRmComparisonEpsilon) {
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
          contentPadding: EdgeInsets.symmetric(
            horizontal: UIConstants.paddingXS,
            vertical: UIConstants.paddingXS,
          ),
          leading: CircleAvatar(
            radius: 14,
            child: Text('${s.setIndex}'),
          ),
          title: Text(
            'Reps: ${s.reps}   Peso: ${s.weight.toStringAsFixed(AppConstants.weightDecimalPlaces)} kg',
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              (e1rm == null)
                  ? const Text('e1RM: —')
                  : Text(
                      'e1RM (${getFormulaDescription(OneRmFormula.epley)}): ${_fmtKg(e1rm)}',
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
              if ((s.note ?? '').trim().isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: UIConstants.paddingXS),
                  child: Text('Nota: ${s.note!.trim()}'),
                ),
            ],
          ),
          trailing: isHighlight
              ? Chip(
                  avatar: const Icon(Icons.star, size: 16),
                  label: const Text('Destaque'),
                  backgroundColor: scheme.secondaryContainer,
                  labelStyle: TextStyle(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        );
      }),
    );
  }
}