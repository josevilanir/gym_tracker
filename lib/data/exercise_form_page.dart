import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import 'package:gym_tracker/core/enums.dart';               // MuscleGroup enum
import 'package:gym_tracker/data/db/app_database.dart';     // databaseProvider + ExercisesCompanion
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
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
        const SnackBar(content: Text('Exercício criado!')),
      );
      // retorna o id criado (útil pra selecionar automaticamente na tela anterior)
      Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
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
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nome do exercício',
                    hintText: 'Ex.: Supino reto',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Informe um nome' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MuscleGroup>(
                  value: _muscle,
                  decoration: const InputDecoration(labelText: 'Grupo muscular'),
                  items: MuscleGroup.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _muscle = v ?? _muscle),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _equipCtrl,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'Equipamento (opcional)',
                    hintText: 'Ex.: Barbell, Dumbbell, Máquina…',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _saving ? null : _submit,
                  icon: _saving
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.save),
                  label: Text(_saving ? 'Salvando...' : 'Salvar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
