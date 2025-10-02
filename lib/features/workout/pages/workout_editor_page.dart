import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/db/app_database.dart';
import '../../workout/controllers/providers.dart';

class WorkoutEditorPage extends ConsumerStatefulWidget {
  const WorkoutEditorPage({super.key});

  @override
  ConsumerState<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends ConsumerState<WorkoutEditorPage> {
  final _titleCtrl = TextEditingController();
  Exercise? _selectedExercise;
  final List<Exercise> _selectedList = [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nova rotina')),
      body: FutureBuilder<List<Exercise>>(
        future: repo.allExercises(),
        builder: (context, snapshot) {
          final all = snapshot.data ?? [];
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Título da rotina',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Exercise>(
                  value: _selectedExercise,
                  decoration: const InputDecoration(labelText: 'Adicionar exercício'),
                  items: all
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedExercise = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _selectedExercise == null
                          ? null
                          : () {
                              setState(() {
                                _selectedList.add(_selectedExercise!);
                                _selectedExercise = null;
                              });
                            },
                      icon: const Icon(Icons.add),
                      label: const Text('Adicionar'),
                    ),
                    const SizedBox(width: 12),
                    Text('${_selectedList.length} exercício(s) selecionado(s)'),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  children: _selectedList
                      .map(
                        (e) => Chip(
                          label: Text(e.name),
                          onDeleted: () {
                            setState(() => _selectedList.remove(e));
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar rotina'),
                  onPressed: _selectedList.isEmpty
                      ? null
                      : () async {
                          // salva rotina como template
                          await repo.saveTemplateFromExercises(
                            name: _titleCtrl.text.trim().isEmpty
                                ? 'Rotina sem nome'
                                : _titleCtrl.text.trim(),
                            exerciseIdsInOrder:
                                _selectedList.map((e) => e.id).toList(),
                          );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Rotina salva com sucesso')),
                            );
                            context.goNamed('today'); // volta para Hoje sem treino ativo
                          }
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
