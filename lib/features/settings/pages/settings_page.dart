// lib/features/settings/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app.dart';
import '../../workout/controllers/providers.dart';
import '../../../data/db/app_database.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<({int total, int done, int exercises})> _loadStats(WidgetRef ref) async {
    final repo = ref.read(workoutRepoProvider);
    final workouts = await repo.listWorkouts(); // todos (ativos + concluídos)
    final total = workouts.length;
    final done = workouts.where((w) => w.done == true).length;
    final ex = await repo.allExercises();
    return (total: total, done: done, exercises: ex.length);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Tema'),
              subtitle: const Text('Alternar entre claro/escuro'),
              trailing: const Icon(Icons.brightness_6),
              onTap: () => toggleTheme(ref),
            ),
          ),
          const SizedBox(height: 8),
          FutureBuilder<({int total, int done, int exercises})>(
            future: _loadStats(ref),
            builder: (context, snap) {
              final stats = snap.data;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: snap.connectionState == ConnectionState.waiting
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _Stat(label: 'Treinos', value: stats?.total ?? 0),
                            _Stat(label: 'Concluídos', value: stats?.done ?? 0),
                            _Stat(label: 'Exercícios', value: stats?.exercises ?? 0),
                          ],
                        ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              title: const Text('Sobre'),
              subtitle: const Text('Gym Tracker • Versão 1.0'),
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Gym Tracker',
                applicationVersion: '1.0',
                children: const [Text('Aplicativo para organizar e acompanhar treinos.')],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final int value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final on = Theme.of(context).colorScheme.onPrimaryContainer;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$value', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: on)),
      ],
    );
  }
}
