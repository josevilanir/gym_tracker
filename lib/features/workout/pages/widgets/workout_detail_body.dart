// lib/features/workout/pages/widgets/workout_detail_body.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../../../core/constants.dart';
import '../../../../data/db/app_database.dart';

import 'exercise_tile.dart';
import 'add_exercise_dialog.dart';

/// Corpo principal da página de detalhes do treino
/// 
/// Exibe a lista de exercícios reordenável com swipe-to-delete
/// e o volume total do treino
class WorkoutDetailBody extends ConsumerStatefulWidget {
  final String workoutId;

  const WorkoutDetailBody({
    super.key,
    required this.workoutId,
  });

  @override
  ConsumerState<WorkoutDetailBody> createState() => WorkoutDetailBodyState();
}

class WorkoutDetailBodyState extends ConsumerState<WorkoutDetailBody> {
  List<WorkoutExercise> _exercises = [];
  double _totalVolume = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Recarrega os dados do treino
  Future<void> reload() => _loadData();

  Future<void> _loadData() async {
    final repo = ref.read(workoutRepoProvider);
    
    final exercises = await repo.listWorkoutExercises(widget.workoutId);
    final volume = await repo.computeWorkoutVolume(widget.workoutId);

    if (!mounted) return;

    setState(() {
      _exercises = List.of(exercises);
      _totalVolume = volume;
    });
  }

  Future<void> _persistOrder() async {
    final repo = ref.read(workoutRepoProvider);
    await repo.reorderExercises(_exercises);
  }

  /// Abre o diálogo para adicionar exercício
  Future<void> openAddExerciseDialog() async {
    await showAddExerciseDialog(
      context: context,
      ref: ref,
      workoutId: widget.workoutId,
    );
    
    await reload();
  }

  @override
  Widget build(BuildContext context) {
    if (_exercises.isEmpty) {
      return const Center(
        child: Text('Sem exercícios neste treino.'),
      );
    }

    return ListView(
      padding: PaddingConstants.allL,
      children: [
        _VolumeCard(volume: _totalVolume),
        SizedBox(height: UIConstants.paddingL),
        _ExercisesList(
          exercises: _exercises,
          onReorder: _onReorder,
          onDismissed: _onDismissed,
          onChanged: reload,
        ),
      ],
    );
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, item);
    });
    
    await _persistOrder();
  }

  Future<void> _onDismissed(WorkoutExercise exercise) async {
    final repo = ref.read(workoutRepoProvider);
    
    await repo.deleteWorkoutExercise(exercise.id);

    setState(() {
      _exercises.removeWhere((e) => e.id == exercise.id);
    });

    await reload();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exercício removido da rotina.'),
        ),
      );
    }
  }
}

/// Card que exibe o volume total do treino
class _VolumeCard extends StatelessWidget {
  final double volume;

  const _VolumeCard({required this.volume});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.indigo.shade50,
      child: Padding(
        padding: PaddingConstants.allL,
        child: Text(
          'Volume total: ${volume.toStringAsFixed(AppConstants.weightDecimalPlaces)} kg',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

/// Lista reordenável de exercícios
class _ExercisesList extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final Future<void> Function(int, int) onReorder;
  final Future<void> Function(WorkoutExercise) onDismissed;
  final Future<void> Function() onChanged;

  const _ExercisesList({
    required this.exercises,
    required this.onReorder,
    required this.onDismissed,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exercises.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final exercise = exercises[index];

        return Padding(
          key: ValueKey(exercise.id),
          padding: EdgeInsets.only(bottom: UIConstants.paddingM),
          child: Dismissible(
            key: ValueKey('dismiss-${exercise.id}'),
            direction: DismissDirection.endToStart,
            background: _DismissBackground(),
            confirmDismiss: (_) => _confirmDismiss(context, exercise),
            onDismissed: (_) => onDismissed(exercise),
            child: ExerciseTile(
              workoutExercise: exercise,
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDismiss(
    BuildContext context,
    WorkoutExercise exercise,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover exercício'),
        content: const Text(
          'Tem certeza que deseja remover este exercício da rotina?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

/// Background exibido ao arrastar exercício para remover
class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      color: Colors.red.withOpacity(0.12),
      padding: PaddingConstants.horizontalL,
      child: const Icon(Icons.delete, color: Colors.red),
    );
  }
}