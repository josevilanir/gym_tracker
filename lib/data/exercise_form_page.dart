// lib/data/exercise_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_tracker/core/enums.dart';
import 'package:gym_tracker/core/validators.dart';  // <- NOVO IMPORT
import 'package:gym_tracker/core/constants.dart';
import 'package:gym_tracker/data/db/app_database.dart';
import 'package:drift/drift.dart' show Value;

class ExerciseFormPage extends ConsumerStatefulWidget {
  const ExerciseFormPage({super.key});

  @override
  ConsumerState<ExerciseFormPage> createState() => _ExerciseFormPageState();
}

class _ExerciseFormPageState extends ConsumerState<ExerciseFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _equipCtrl = TextEditingController();
  MuscleGroup _muscle = MuscleGroup.chest;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _equipCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // Valida o formulário completo
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, corrija os erros antes de salvar'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final db = ref.read(databaseProvider);
      final id = const Uuid().v4();

      await db.insertExercise(
        ExercisesCompanion.insert(
          id: id,
          name: _nameCtrl.text.trim(),
          muscleGroup: _muscle.name,
          equipment: _equipCtrl.text.trim().isEmpty
              ? const Value.absent()
              : Value(_equipCtrl.text.trim()),
          isCustom: const Value(true),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Exercício criado com sucesso!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // retorna o id criado
      Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo exercício')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // Nome do exercício (OBRIGATÓRIO)
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Nome do exercício *',
                    hintText: 'Ex.: Supino reto',
                    helperText: 'Mín. 2 caracteres',
                    prefixIcon: const Icon(Icons.fitness_center),
                    counterText: '${_nameCtrl.text.length}/${AppConstants.maxExerciseNameLength}',
                  ),
                  maxLength: AppConstants.maxExerciseNameLength,
                  validator: Validators.exerciseName,  // <- VALIDAÇÃO APLICADA
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => setState(() {}), // atualiza counter
                ),
                const SizedBox(height: 16),

                // Grupo muscular
                DropdownButtonFormField<MuscleGroup>(
                  value: _muscle,
                  decoration: const InputDecoration(
                    labelText: 'Grupo muscular *',
                    prefixIcon: Icon(Icons.accessibility_new),
                  ),
                  items: MuscleGroup.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(_getMuscleGroupLabel(m)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _muscle = v ?? _muscle),
                ),
                const SizedBox(height: 16),

                // Equipamento (OPCIONAL)
                TextFormField(
                  controller: _equipCtrl,
                  textInputAction: TextInputAction.done,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Equipamento (opcional)',
                    hintText: 'Ex.: Barra, Halter, Máquina...',
                    prefixIcon: Icon(Icons.construction),
                  ),
                  validator: Validators.equipment,  // <- VALIDAÇÃO APLICADA
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 24),

                // Botão de salvar
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Salvando...' : 'Salvar exercício'),
                ),
                const SizedBox(height: 8),

                // Texto de ajuda
                const Text(
                  '* Campos obrigatórios',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMuscleGroupLabel(MuscleGroup group) {
    switch (group) {
      case MuscleGroup.chest:
        return 'Peito';
      case MuscleGroup.back:
        return 'Costas';
      case MuscleGroup.legs:
        return 'Pernas';
      case MuscleGroup.shoulders:
        return 'Ombros';
      case MuscleGroup.biceps:
        return 'Bíceps';
      case MuscleGroup.triceps:
        return 'Tríceps';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.glutes:
        return 'Glúteos';
      case MuscleGroup.fullbody:
        return 'Corpo inteiro';
      case MuscleGroup.cardio:
        return 'Cardio';
      case MuscleGroup.other:
        return 'Outro';
    }
  }
}