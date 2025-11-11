import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators.dart';
import '../../../core/constants.dart';
import '../../../data/db/app_database.dart';
import '../../workout/controllers/providers.dart';

class WorkoutEditorPage extends ConsumerStatefulWidget {
  const WorkoutEditorPage({super.key});

  @override
  ConsumerState<WorkoutEditorPage> createState() => _WorkoutEditorPageState();
}

class _WorkoutEditorPageState extends ConsumerState<WorkoutEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  Exercise? _selectedExercise;
  final List<Exercise> _selectedList = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveTemplate() async {
    // Valida o formulário
    if (!(_formKey.currentState?.validate() ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Por favor, corrija os erros antes de salvar'),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: AppConstants.snackBarErrorDuration,
        ),
      );
      return;
    }

    // Verifica se há exercícios
    if (_selectedList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_outlined, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Adicione pelo menos um exercício à rotina'),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(workoutRepoProvider);
      
      // IMPORTANTE: Captura os valores ANTES de qualquer operação assíncrona
      final templateName = _titleCtrl.text.trim();
      final exerciseIds = _selectedList.map((e) => e.id).toList();
      
      // Cria o template primeiro
      final templateId = await repo.createTemplate(
        name: templateName,
      );
      
      // Depois adiciona os exercícios
      await repo.setTemplateExercises(
        templateId: templateId,
        exerciseIdsInOrder: exerciseIds,
      );

      if (!mounted) return;

      // Navega de volta
      context.pop();

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erro ao salvar rotina: $e')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          duration: AppConstants.snackBarErrorDuration,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _addExercise() {
    if (_selectedExercise == null) return;

    if (_selectedList.contains(_selectedExercise!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('Exercício "${_selectedExercise!.name}" já está na rotina'),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _selectedList.add(_selectedExercise!);
      _selectedExercise = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white),
            SizedBox(width: 12),
            Text('Exercício adicionado'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar todos os exercícios?'),
        content: Text(
          'Você tem ${_selectedList.length} exercício(s) adicionado(s). Deseja remover todos?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _selectedList.clear());
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.delete_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Text('Todos os exercícios foram removidos'),
                    ],
                  ),
                  backgroundColor: Colors.orange,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova rotina'),
        actions: [
          // Botão de salvar na AppBar
          if (!_isSaving)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Salvar rotina',
              onPressed: _saveTemplate,
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: FutureBuilder<List<Exercise>>(
        future: repo.allExercises(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando exercícios...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
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
                      'Erro ao carregar exercícios',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => setState(() {}),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final all = snapshot.data ?? [];

          if (all.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.3),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Nenhum exercício disponível',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie exercícios no catálogo antes de criar uma rotina',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: () => context.pushNamed('catalog'),
                      icon: const Icon(Icons.add),
                      label: const Text('Ir para Catálogo'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Campo de título com validação
                  TextFormField(
                    controller: _titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Título da rotina *',
                      hintText: 'Ex: Treino A - Peito e Tríceps',
                      helperText: 'Mínimo 3 caracteres',
                      prefixIcon: const Icon(Icons.bookmark),
                      counterText:
                          '${_titleCtrl.text.length}/${AppConstants.maxWorkoutTitleLength}',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    maxLength: AppConstants.maxWorkoutTitleLength,
                    validator: Validators.templateName,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onChanged: (_) => setState(() {}), // atualiza contador
                  ),
                  const SizedBox(height: 16),

                  // Dropdown para selecionar exercício
                  DropdownButtonFormField<Exercise>(
                    value: _selectedExercise,
                    decoration: const InputDecoration(
                      labelText: 'Adicionar exercício',
                      prefixIcon: Icon(Icons.fitness_center),
                      helperText: 'Selecione para adicionar à rotina',
                    ),
                    items: all
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedExercise = v),
                  ),
                  const SizedBox(height: 12),

                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _selectedExercise == null ? null : _addExercise,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 20),
                              SizedBox(width: 8),
                              Text('Adicionar'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _selectedList.isEmpty ? null : _clearAll,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.clear_all, size: 20),
                              SizedBox(width: 8),
                              Text('Limpar tudo'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lista de exercícios selecionados
                  Expanded(
                    child: _selectedList.isEmpty
                        ? Card(
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.fitness_center,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.3),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Nenhum exercício adicionado',
                                      style: Theme.of(context).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Selecione exercícios acima para criar sua rotina',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        : Card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.reorder, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Exercícios da rotina',
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                      const Spacer(),
                                      Chip(
                                        label: Text('${_selectedList.length}'),
                                        visualDensity: VisualDensity.compact,
                                        avatar: const Icon(Icons.fitness_center, size: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Expanded(
                                  child: ReorderableListView.builder(
                                    itemCount: _selectedList.length,
                                    onReorder: (oldIndex, newIndex) {
                                      setState(() {
                                        if (newIndex > oldIndex) {
                                          newIndex -= 1;
                                        }
                                        final item = _selectedList.removeAt(oldIndex);
                                        _selectedList.insert(newIndex, item);
                                      });
                                    },
                                    itemBuilder: (context, index) {
                                      final ex = _selectedList[index];
                                      return Card(
                                        key: ValueKey(ex.id),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Theme.of(context).colorScheme.primaryContainer,
                                            foregroundColor:
                                                Theme.of(context).colorScheme.onPrimaryContainer,
                                            child: Text('${index + 1}'),
                                          ),
                                          title: Text(ex.name),
                                          subtitle: Row(
                                            children: [
                                              Icon(
                                                Icons.label,
                                                size: 14,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _getMuscleGroupLabel(ex.muscleGroup),
                                              ),
                                            ],
                                          ),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.close),
                                            tooltip: 'Remover exercício',
                                            onPressed: () {
                                              setState(() {
                                                _selectedList.removeAt(index);
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    '"${ex.name}" removido',
                                                  ),
                                                  backgroundColor: Colors.orange,
                                                  behavior: SnackBarBehavior.floating,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Botão de salvar (rodapé)
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveTemplate,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_isSaving ? 'Salvando...' : 'Salvar rotina'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '* Campos obrigatórios${_selectedList.isNotEmpty ? '\n💡 Dica: Arraste os exercícios para reordenar' : ''}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getMuscleGroupLabel(String group) {
    switch (group) {
      case 'chest':
        return 'Peito';
      case 'back':
        return 'Costas';
      case 'legs':
        return 'Pernas';
      case 'shoulders':
        return 'Ombros';
      case 'biceps':
        return 'Bíceps';
      case 'triceps':
        return 'Tríceps';
      case 'core':
        return 'Core';
      case 'glutes':
        return 'Glúteos';
      case 'fullbody':
        return 'Corpo inteiro';
      default:
        return 'Geral';
    }
  }
}