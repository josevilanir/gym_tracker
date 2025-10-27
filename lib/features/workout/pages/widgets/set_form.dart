// lib/features/workout/pages/widgets/set_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../../../core/constants.dart';
import '../../../../data/db/app_database.dart';

/// Formulário para adicionar nova série ao exercício
/// 
/// Permite inserir repetições e peso, com validação de valores,
/// sugestões de repetições e copiar dados da última série
class SetForm extends ConsumerStatefulWidget {
  final WorkoutExercise workoutExercise;
  final Future<void> Function() onChanged;

  const SetForm({
    super.key,
    required this.workoutExercise,
    required this.onChanged,
  });

  @override
  ConsumerState<SetForm> createState() => _SetFormState();
}

class _SetFormState extends ConsumerState<SetForm> {
  final _repsController = TextEditingController();
  final _weightController = TextEditingController();
  
  // Sugestões rápidas de repetições
  static const List<int> _repsSuggestions = [6, 8, 10, 12, 15, 20];

  @override
  void dispose() {
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Padding(
        padding: PaddingConstants.allM,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header com título e botão de copiar última série
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adicionar série',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                FutureBuilder<List<SetEntry>>(
                  future: repo.listSets(widget.workoutExercise.id),
                  builder: (context, snapshot) {
                    final sets = snapshot.data ?? [];
                    if (sets.isEmpty) return const SizedBox.shrink();

                    final lastSet = sets.last;
                    return TextButton.icon(
                      icon: const Icon(Icons.content_copy, size: 16),
                      label: const Text('Copiar última'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _copyLastSet(lastSet),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: UIConstants.paddingS),

            // Sugestões rápidas de repetições
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _repsSuggestions.map((reps) {
                return ActionChip(
                  label: Text('$reps reps'),
                  visualDensity: VisualDensity.compact,
                  onPressed: () {
                    _repsController.text = reps.toString();
                    // Foca no campo de peso após selecionar reps
                    FocusScope.of(context).nextFocus();
                  },
                );
              }).toList(),
            ),
            SizedBox(height: UIConstants.paddingM),

            // Campos de entrada
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Reps',
                      hintText: 'Ex: 12',
                      helperText: '${AppConstants.minReps}-${AppConstants.maxReps}',
                      errorMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                    validator: _validateReps,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                SizedBox(width: UIConstants.paddingM),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Peso (kg)',
                      hintText: 'Ex: 25.0',
                      helperText: '${AppConstants.minWeight}-${AppConstants.maxWeight}',
                      errorMaxLines: 2,
                      border: const OutlineInputBorder(),
                    ),
                    validator: _validateWeight,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _addSet(),
                  ),
                ),
              ],
            ),
            SizedBox(height: UIConstants.paddingM),

            // Botão de adicionar (full width na parte de baixo)
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Adicionar série'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: _addSet,
            ),
          ],
        ),
      ),
    );
  }

  /// Copia os dados da última série para os campos
  void _copyLastSet(SetEntry lastSet) {
    setState(() {
      _repsController.text = lastSet.reps.toString();
      _weightController.text = lastSet.weight.toStringAsFixed(
        AppConstants.weightDecimalPlaces,
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dados da última série copiados'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  String? _validateReps(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o número de reps';
    }

    final reps = int.tryParse(value.trim());
    if (reps == null) {
      return 'Valor inválido';
    }

    if (reps < AppConstants.minReps) {
      return 'Mínimo: ${AppConstants.minReps}';
    }

    if (reps > AppConstants.maxReps) {
      return 'Máximo: ${AppConstants.maxReps}';
    }

    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o peso';
    }

    final weight = double.tryParse(value.trim().replaceAll(',', '.'));
    if (weight == null) {
      return 'Valor inválido';
    }

    if (weight < AppConstants.minWeight) {
      return 'Mínimo: ${AppConstants.minWeight} kg';
    }

    if (weight > AppConstants.maxWeight) {
      return 'Máximo: ${AppConstants.maxWeight} kg';
    }

    return null;
  }

  Future<void> _addSet() async {
    // Valida antes de salvar
    final repsError = _validateReps(_repsController.text);
    final weightError = _validateWeight(_weightController.text);

    if (repsError != null || weightError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            repsError ?? weightError ?? AppConstants.errorInvalidReps,
          ),
          duration: AppConstants.snackBarErrorDuration,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final reps = int.parse(_repsController.text.trim());
    final weight = double.parse(
      _weightController.text.trim().replaceAll(',', '.'),
    );

    final repo = ref.read(workoutRepoProvider);

    await repo.addSetQuick(
      workoutExerciseId: widget.workoutExercise.id,
      reps: reps,
      weight: weight,
    );

    if (!mounted) return;

    _repsController.clear();
    _weightController.clear();

    await widget.onChanged();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppConstants.successSetAdded),
        duration: AppConstants.snackBarSuccessDuration,
      ),
    );
  }
}