// lib/features/workout/pages/workout_detail_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/providers.dart';
import '../../../core/constants.dart';
import '../../../data/db/app_database.dart';

import 'widgets/workout_detail_body.dart';
import 'widgets/rest_timer_bar.dart';

/// Página principal de detalhes e edição de um treino ativo
/// 
/// Permite adicionar exercícios, registrar séries, reordenar exercícios
/// salvar como template e concluir o treino.
class WorkoutDetailPage extends ConsumerStatefulWidget {
  final String workoutId;
  
  const WorkoutDetailPage({
    super.key,
    required this.workoutId,
  });

  @override
  ConsumerState<WorkoutDetailPage> createState() => _WorkoutDetailPageState();
}

class _WorkoutDetailPageState extends ConsumerState<WorkoutDetailPage> {
  final GlobalKey<WorkoutDetailBodyState> _bodyKey = GlobalKey<WorkoutDetailBodyState>();

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return FutureBuilder<Workout?>(
      future: repo.getWorkout(widget.workoutId),
      builder: (context, snapshot) {
        final workout = snapshot.data;
        final title = workout?.title ?? 'Treino';
        final dateStr = workout == null
            ? ''
            : DateFormat(AppConstants.dateTimeFormatFull).format(
                DateTime.fromMillisecondsSinceEpoch(workout.dateEpoch),
              );

        return Scaffold(
          appBar: AppBar(
            title: Text('$title ($dateStr)'),
            actions: [
              _SaveAsTemplateButton(workoutId: widget.workoutId, currentTitle: title),
              _CompleteWorkoutButton(workoutId: widget.workoutId),
            ],
          ),
          body: WorkoutDetailBody(
            key: _bodyKey,
            workoutId: widget.workoutId,
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Adicionar exercício'),
            onPressed: () => _bodyKey.currentState?.openAddExerciseDialog(),
          ),
          bottomNavigationBar: const RestTimerBar(),
        );
      },
    );
  }
}

/// Botão para salvar o treino atual como template/rotina
class _SaveAsTemplateButton extends ConsumerWidget {
  final String workoutId;
  final String currentTitle;

  const _SaveAsTemplateButton({
    required this.workoutId,
    required this.currentTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Salvar como rotina',
      icon: const Icon(Icons.bookmark_add_outlined),
      onPressed: () => _showSaveAsTemplateDialog(context, ref),
    );
  }

  Future<void> _showSaveAsTemplateDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final repo = ref.read(workoutRepoProvider);
    final nameController = TextEditingController(text: currentTitle);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Salvar rotina'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nome da rotina'),
          maxLength: AppConstants.maxWorkoutTitleLength,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, nameController.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    nameController.dispose();

    if (name != null && name.isNotEmpty && context.mounted) {
      await repo.saveWorkoutAsTemplate(
        workoutId: workoutId,
        name: name,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppConstants.successTemplateCreated),
          duration: AppConstants.snackBarSuccessDuration,
        ),
      );
    }
  }
}

/// Botão para marcar o treino como concluído
class _CompleteWorkoutButton extends ConsumerWidget {
  final String workoutId;

  const _CompleteWorkoutButton({required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Concluir treino',
      icon: const Icon(Icons.check),
      onPressed: () => _completeWorkout(context, ref),
    );
  }

  Future<void> _completeWorkout(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(workoutRepoProvider);
    
    await repo.markDone(workoutId, true);

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppConstants.successWorkoutCompleted),
        duration: AppConstants.snackBarSuccessDuration,
      ),
    );

    Navigator.pop(context);
  }
}