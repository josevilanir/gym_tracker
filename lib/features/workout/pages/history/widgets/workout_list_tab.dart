// lib/features/workout/pages/history/widgets/workout_list_tab.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants.dart';
import '../../../controllers/providers.dart';
import '../../../../../data/db/app_database.dart';

class WorkoutListTab extends ConsumerWidget {
  final (DateTime, DateTime) Function() currentBounds;
  final VoidCallback onRegisterWorkout;

  const WorkoutListTab({
    super.key,
    required this.currentBounds,
    required this.onRegisterWorkout,
  });

  Future<List<Workout>> _loadWorkouts(WidgetRef ref) async {
    final repo = ref.read(workoutRepoProvider);
    final (start, end) = currentBounds();
    return await repo.listFinishedWorkoutsBetween(start: start, end: end);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);

    return FutureBuilder<List<Workout>>(
      future: _loadWorkouts(ref),
      builder: (context, wSnap) {
        if (wSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (wSnap.hasError) {
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
                    'Erro ao carregar treinos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${wSnap.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      // Force rebuild
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

        final workouts = wSnap.data ?? <Workout>[];

        if (workouts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nenhum treino concluído',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhum treino concluído no período selecionado',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: onRegisterWorkout,
                    icon: const Icon(Icons.add),
                    label: const Text('Registrar treino'),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workouts.length,
          itemBuilder: (context, index) {
            final w = workouts[index];
            return FutureBuilder(
              future: Future.wait([
                repo.countExercisesInWorkout(w.id),
                repo.countSetsInWorkout(w.id),
              ]),
              builder: (context, AsyncSnapshot<List<int>> s2) {
                if (s2.connectionState == ConnectionState.waiting) {
                  return const Card(
                    child: ListTile(
                      leading: CircularProgressIndicator(),
                      title: Text('Carregando...'),
                    ),
                  );
                }

                final exCount = (s2.data != null && s2.data!.isNotEmpty) ? s2.data![0] : 0;
                final setCount = (s2.data != null && s2.data!.length > 1) ? s2.data![1] : 0;
                final date = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
                final dateStr = DateFormat('dd/MM, HH:mm').format(date);
                final title = (w.title?.trim().isNotEmpty ?? false) ? w.title! : 'Treino sem nome';

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text(title),
                    subtitle: Text('Concluído em $dateStr'),
                    trailing: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _ChipStat(icon: Icons.fitness_center, label: '$exCount'),
                        _ChipStat(icon: Icons.format_list_numbered, label: '$setCount'),
                      ],
                    ),
                    onTap: () => context.pushNamed(
                      'history_workout_detail',
                      pathParameters: {'id': w.id},
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ChipStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChipStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}