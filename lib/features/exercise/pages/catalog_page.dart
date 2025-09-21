// lib/features/exercise/pages/catalog_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workout/controllers/providers.dart';
import '../../../data/db/app_database.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Exercícios')),
      body: FutureBuilder<List<Exercise>>(
        future: repo.allExercises(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Nenhum exercício cadastrado ainda.'));
          }
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final e = items[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text(e.name),
                  subtitle: Text(e.muscleGroup),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExerciseDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar'),
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final groupCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo exercício'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: groupCtrl,
              decoration: const InputDecoration(labelText: 'Grupo muscular'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final group = groupCtrl.text.trim();
              if (name.isEmpty || group.isEmpty) return;
              await ref.read(workoutRepoProvider).createExercise(
                    name: name,
                    muscleGroup: group,
                  );
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Exercício "$name" adicionado.')),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
