// lib/features/exercise/pages/catalog_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../workout/controllers/providers.dart';  // ✅ certo
import '../../../data/db/app_database.dart';

class CatalogPage extends ConsumerWidget {
  const CatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider); // ✅ corrigido

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
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Nenhum exercício cadastrado ainda.'),
                ],
              ),
            );
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
    );
  }
}
