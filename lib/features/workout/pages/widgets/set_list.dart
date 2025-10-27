// lib/features/workout/pages/widgets/set_list.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controllers/providers.dart';
import '../../../../core/constants.dart';
import '../../../../data/db/app_database.dart';

/// Lista as séries registradas para um exercício
/// 
/// Permite adicionar notas e remover séries
class SetList extends ConsumerWidget {
  final WorkoutExercise workoutExercise;
  final Future<void> Function() onChanged;

  const SetList({
    super.key,
    required this.workoutExercise,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);

    return FutureBuilder<List<SetEntry>>(
      future: repo.listSets(workoutExercise.id),
      builder: (context, snapshot) {
        final sets = snapshot.data ?? [];

        if (sets.isEmpty) {
          return const Text('Nenhuma série registrada ainda.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Séries registradas:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: UIConstants.paddingS),
            ...sets.map((set) => _SetItem(
                  set: set,
                  onChanged: onChanged,
                )),
          ],
        );
      },
    );
  }
}

/// Item individual de série
class _SetItem extends ConsumerWidget {
  final SetEntry set;
  final Future<void> Function() onChanged;

  const _SetItem({
    required this.set,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.only(bottom: UIConstants.paddingS),
      child: ListTile(
        dense: true,
        title: Row(
          children: [
            Text(
              'Série ${set.setIndex}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(width: UIConstants.paddingS),
            Text(
              '${set.reps} reps × ${set.weight.toStringAsFixed(AppConstants.weightDecimalPlaces)} kg',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        subtitle: (set.note?.trim().isNotEmpty ?? false)
            ? Padding(
                padding: EdgeInsets.only(top: UIConstants.paddingXS),
                child: Text(
                  'Nota: ${set.note!.trim()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: 'Adicionar nota',
              icon: const Icon(Icons.edit_note_outlined),
              onPressed: () => _editNote(context, ref),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Remover série',
              onPressed: () => _deleteSet(context, ref),
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _editNote(BuildContext context, WidgetRef ref) async {
  final controller = TextEditingController(text: set.note ?? '');
  String? newNote;

  try {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nota da série'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: AppConstants.maxNoteLength,
          decoration: const InputDecoration(
            hintText: 'Ex.: pegada aberta, falha na 9ª rep, dor leve...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              newNote = controller.text.trim();
              Navigator.pop(ctx, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    // Verificação 1: após showDialog
    if (!context.mounted) return;

    if (result == true && newNote != null) {
      final repo = ref.read(workoutRepoProvider);
      
      await repo.updateSetNote(
        set.id,
        newNote!.isEmpty ? null : newNote,
      );

      // Verificação 2: após updateSetNote
      if (!context.mounted) return;

      await onChanged();

      // Verificação 3: após onChanged
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Nota salva.'),
          duration: AppConstants.snackBarSuccessDuration,
        ),
      );
    }
  } finally {
    controller.dispose();
  }
}

Future<void> _deleteSet(BuildContext context, WidgetRef ref) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Remover série'),
      content: Text(
        'Remover a série ${set.setIndex} '
        '(${set.reps} reps, ${set.weight.toStringAsFixed(AppConstants.weightDecimalPlaces)} kg)?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Remover'),
        ),
      ],
    ),
  );

  // Verificação 1: após showDialog
  if (!context.mounted) return;

  if (confirm == true) {
    final repo = ref.read(workoutRepoProvider);
    
    await repo.deleteSet(set.id);

    // Verificação 2: após deleteSet
    if (!context.mounted) return;

    await onChanged();

    // Verificação 3: após onChanged
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Série removida.'),
        duration: AppConstants.snackBarSuccessDuration,
      ),
    );
  }
}
}