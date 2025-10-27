// lib/features/workout/pages/widgets/exercise_tile.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../../../core/constants.dart';
import '../../../../data/db/app_database.dart';

import 'set_form.dart';
import 'set_list.dart';

/// Widget que exibe um exercício individual dentro do treino
/// 
/// Mostra o nome do exercício, checkbox para marcar como concluído,
/// lista de séries e formulário para adicionar novas séries (colapsável)
class ExerciseTile extends ConsumerStatefulWidget {
  final WorkoutExercise workoutExercise;
  final Future<void> Function() onChanged;

  const ExerciseTile({
    super.key,
    required this.workoutExercise,
    required this.onChanged,
  });

  @override
  ConsumerState<ExerciseTile> createState() => _ExerciseTileState();
}

class _ExerciseTileState extends ConsumerState<ExerciseTile> {
  bool _isFormExpanded = true; // Formulário expandido por padrão

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return FutureBuilder<Exercise?>(
      future: repo.getExercise(widget.workoutExercise.exerciseId),
      builder: (context, snapshot) {
        final exercise = snapshot.data;
        final isDone = widget.workoutExercise.done;
        final isCustom = exercise?.isCustom ?? false;

        return Card(
          color: isDone ? Colors.green.shade50 : null,
          child: Padding(
            padding: PaddingConstants.allM,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ExerciseHeader(
                  exercise: exercise,
                  workoutExercise: widget.workoutExercise,
                  isCustom: isCustom,
                  isDone: isDone,
                  onDoneChanged: _onDoneChanged,
                ),
                SizedBox(height: UIConstants.paddingM),
                
                // Lista de séries (sempre visível)
                SetList(
                  workoutExercise: widget.workoutExercise,
                  onChanged: widget.onChanged,
                ),
                
                // Botões de controle
                SizedBox(height: UIConstants.paddingM),
                _FormControls(
                  isExpanded: _isFormExpanded,
                  onToggle: () {
                    setState(() {
                      _isFormExpanded = !_isFormExpanded;
                    });
                  },
                ),
                
                // Formulário de adicionar série (colapsável)
                if (_isFormExpanded) ...[
                  SizedBox(height: UIConstants.paddingM),
                  SetForm(
                    workoutExercise: widget.workoutExercise,
                    onChanged: widget.onChanged,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDoneChanged(bool? value) async {
    final repo = ref.read(workoutRepoProvider);
    
    await repo.setExerciseDone(
      widget.workoutExercise.id,
      value ?? false,
    );
    
    await widget.onChanged();
  }
}

/// Cabeçalho do exercício com nome, tag custom e checkbox
class _ExerciseHeader extends StatelessWidget {
  final Exercise? exercise;
  final WorkoutExercise workoutExercise;
  final bool isCustom;
  final bool isDone;
  final ValueChanged<bool?> onDoneChanged;

  const _ExerciseHeader({
    required this.exercise,
    required this.workoutExercise,
    required this.isCustom,
    required this.isDone,
    required this.onDoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.drag_handle),
        SizedBox(width: UIConstants.paddingS),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: UIConstants.paddingS,
            children: [
              Text(
                exercise?.name ?? 'Exercício',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (isCustom)
                const Chip(
                  label: Text('custom'),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        Checkbox(
          value: isDone,
          onChanged: onDoneChanged,
        ),
      ],
    );
  }
}

/// Controles para expandir/colapsar o formulário
class _FormControls extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const _FormControls({
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      // Quando expandido: botão para fechar
      return OutlinedButton.icon(
        icon: const Icon(Icons.expand_less),
        label: const Text('Fechar séries'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
        ),
        onPressed: onToggle,
      );
    } else {
      // Quando colapsado: botão para adicionar mais
      return FilledButton.icon(
        icon: const Icon(Icons.add),
        label: const Text('Adicionar mais séries'),
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 40),
        ),
        onPressed: onToggle,
      );
    }
  }
}