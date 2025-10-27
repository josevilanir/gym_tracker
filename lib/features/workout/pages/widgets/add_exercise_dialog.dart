// lib/features/workout/pages/widgets/add_exercise_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../../../core/constants.dart';
import '../../../../core/enums.dart';
import '../../../../data/db/app_database.dart';

/// Mostra diálogo para adicionar exercício ao treino
/// 
/// Permite buscar exercícios existentes ou criar novo exercício personalizado
Future<void> showAddExerciseDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String workoutId,
}) async {
  final repo = ref.read(workoutRepoProvider);
  List<Exercise> allExercises = await repo.allExercises();
  final searchController = TextEditingController();

  await showDialog(
    context: context,
    builder: (ctx) => _AddExerciseDialog(
      workoutId: workoutId,
      allExercises: allExercises,
      searchController: searchController,
    ),
  );

  searchController.dispose();
}

class _AddExerciseDialog extends ConsumerStatefulWidget {
  final String workoutId;
  final List<Exercise> allExercises;
  final TextEditingController searchController;

  const _AddExerciseDialog({
    required this.workoutId,
    required this.allExercises,
    required this.searchController,
  });

  @override
  ConsumerState<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends ConsumerState<_AddExerciseDialog> {
  late List<Exercise> _allExercises;
  late List<Exercise> _filteredExercises;
  Exercise? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _allExercises = widget.allExercises;
    _filteredExercises = _allExercises;
  }

  void _applyFilter() {
    final query = widget.searchController.text.trim().toLowerCase();
    
    setState(() {
      _filteredExercises = query.isEmpty
          ? _allExercises
          : _allExercises
              .where((e) => e.name.toLowerCase().contains(query))
              .toList();
    });
  }

  Future<void> _refreshExercises() async {
    final repo = ref.read(workoutRepoProvider);
    _allExercises = await repo.allExercises();
    _applyFilter();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Adicionar exercício'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.searchController,
            decoration: const InputDecoration(
              labelText: 'Buscar',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (_) => _applyFilter(),
          ),
          SizedBox(height: UIConstants.paddingM),
          DropdownButtonFormField<Exercise>(
            value: _selectedExercise,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Selecione'),
            items: _filteredExercises
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedExercise = v),
          ),
          SizedBox(height: UIConstants.paddingS),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Novo exercício'),
              onPressed: _createCustomExercise,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _selectedExercise == null ? null : _addExercise,
          child: const Text('Adicionar'),
        ),
      ],
    );
  }

  Future<void> _createCustomExercise() async {
    final createdId = await showDialog<String>(
      context: context,
      builder: (ctx) => _CreateExerciseDialog(),
    );

    if (createdId != null) {
      await _refreshExercises();
      
      _selectedExercise = _allExercises.firstWhere(
        (e) => e.id == createdId,
        orElse: () => _filteredExercises.first,
      );
      
      setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConstants.successExerciseCreated),
            duration: AppConstants.snackBarSuccessDuration,
          ),
        );
      }
    }
  }

  Future<void> _addExercise() async {
    if (_selectedExercise == null) return;

    final repo = ref.read(workoutRepoProvider);
    
    await repo.addExerciseAtEnd(widget.workoutId, _selectedExercise!.id);

    if (!mounted) return;

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppConstants.successExerciseAdded),
        duration: AppConstants.snackBarSuccessDuration,
      ),
    );
  }
}

/// Diálogo para criar novo exercício personalizado
class _CreateExerciseDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateExerciseDialog> createState() =>
      _CreateExerciseDialogState();
}

class _CreateExerciseDialogState extends ConsumerState<_CreateExerciseDialog> {
  final _nameController = TextEditingController();
  final _equipmentController = TextEditingController();
  MuscleGroup _selectedMuscle = MuscleGroup.chest;

  @override
  void dispose() {
    _nameController.dispose();
    _equipmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo exercício'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome'),
            maxLength: AppConstants.maxExerciseNameLength,
          ),
          SizedBox(height: UIConstants.paddingS),
          DropdownButtonFormField<MuscleGroup>(
            value: _selectedMuscle,
            decoration: const InputDecoration(labelText: 'Grupo muscular'),
            items: MuscleGroup.values
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.name),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedMuscle = v ?? MuscleGroup.chest;
            }),
          ),
          SizedBox(height: UIConstants.paddingS),
          TextField(
            controller: _equipmentController,
            decoration: const InputDecoration(
              labelText: 'Equipamento (opcional)',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _createExercise,
          child: const Text('Criar'),
        ),
      ],
    );
  }

  Future<void> _createExercise() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final repo = ref.read(workoutRepoProvider);
    
    final id = await repo.createCustomExercise(
      name: name,
      muscle: _selectedMuscle,
      equipment: _equipmentController.text.trim().isEmpty
          ? null
          : _equipmentController.text.trim(),
    );

    if (!mounted) return;
    
    Navigator.pop(context, id);
  }
}