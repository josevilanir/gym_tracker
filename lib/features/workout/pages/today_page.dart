import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../controllers/providers.dart';
import '../../../data/db/app_database.dart';

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed = ref.watch(seedFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hoje'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.pushNamed('history'),
            tooltip: 'Histórico',
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2),
            onPressed: () => context.pushNamed('catalog'),
            tooltip: 'Catálogo',
          ),
        ],
      ),
      body: seed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao iniciar: $e')),
        data: (_) => const _TodayContent(),
      ),
      floatingActionButton: const _StartFab(),
    );
  }
}

class _TodayContent extends ConsumerWidget {
  const _TodayContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);

    return FutureBuilder<List<Workout>>(
      future: repo.listActiveWorkouts(), // só ativos
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sem treinos ativos.'),
                const SizedBox(height: 8),
                const Text('Crie um novo ou use uma rotina salva.'),
                const SizedBox(height: 16),
                const _StartFab(inline: true),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: items.length,
          itemBuilder: (context, i) {
            final w = items[i];
            final date = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
            final f = DateFormat('dd/MM/yyyy HH:mm');

            return Card(
              child: ListTile(
                title: Text(w.title ?? 'Treino ${i + 1}'),
                subtitle: Text('${f.format(date)} • Em andamento'),
                trailing: const Icon(Icons.schedule),
                onTap: () {
                  // Abre a NOVA tela de detalhe do treino
                  context.pushNamed('workout_detail', pathParameters: {'id': w.id});
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _StartFab extends ConsumerWidget {
  final bool inline;
  const _StartFab({this.inline = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void openSheet() => showModalBottomSheet(
          context: context,
          showDragHandle: true,
          builder: (_) => _StartSheet(),
        );

    if (inline) {
      return FilledButton.icon(
        icon: const Icon(Icons.playlist_add),
        label: const Text('Começar'),
        onPressed: openSheet,
      );
    }

    return FloatingActionButton.extended(
      onPressed: openSheet,
      label: const Text('Começar'),
      icon: const Icon(Icons.playlist_add),
    );
  }
}

class _StartSheet extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(workoutRepoProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder(
          future: repo.listTemplates(),
          builder: (context, snap) {
            final templates = (snap.data ?? []) as List<Template>;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.fiber_new),
                  label: const Text('Novo do zero'),
                  onPressed: () {
                    Navigator.pop(context);
                    context.pushNamed('workout_new');
                  },
                ),
                const SizedBox(height: 12),
                Text('Ou use uma rotina salva:', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (templates.isEmpty)
                  const Text('Nenhuma rotina salva ainda.')
                else
                  ...templates.map((t) => ListTile(
                        leading: const Icon(Icons.auto_awesome_motion),
                        title: Text(t.name),
                        onTap: () async {
                          final newId = await repo.createWorkoutFromTemplate(
                            templateId: t.id,
                            title: t.name,
                          );
                          if (context.mounted) {
                            Navigator.pop(context);
                            context.pushNamed('workout_detail', pathParameters: {'id': newId});
                          }
                        },
                      )),
              ],
            );
          },
        ),
      ),
    );
  }
}
