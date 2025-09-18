// lib/features/workout/pages/today_page.dart
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
            tooltip: 'Notificações (em breve)',
            onPressed: () {},
            icon: const Icon(Icons.alarm),
          ),
          IconButton(
            tooltip: 'Templates',
            onPressed: () => context.pushNamed('catalog'),
            icon: const Icon(Icons.auto_awesome_motion),
          ),
        ],
      ),
      body: seed.when(
        data: (_) => const _TodayContent(),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro ao preparar app: $e')),
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

    return StreamBuilder<List<Workout>>(
      // ✅ agora escutamos o banco; a lista atualiza sozinha
      stream: repo.watchActiveWorkouts(),
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
          itemBuilder: (context, index) {
            final w = items[index];
            final date = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
            final dateStr = DateFormat('dd/MM, HH:mm').format(date);
            final title = (w.title?.trim().isNotEmpty ?? false) ? w.title! : 'Treino sem nome';

            return Card(
              child: ListTile(
                leading: const Icon(Icons.fitness_center),
                title: Text(title),
                subtitle: Text('Iniciado em $dateStr'),
                trailing: IconButton(
                  tooltip: 'Concluir',
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () async {
                    await repo.markDone(w.id, true); // ✅ some da lista
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Treino concluído!')),
                      );
                    }
                  },
                ),
                onTap: () => context.pushNamed('workout_detail', pathParameters: {'id': w.id}),
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
    return Padding(
      padding: inline ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8, right: 8),
      child: FloatingActionButton.extended(
        heroTag: inline ? 'start_inline' : 'start_fab',
        onPressed: () => _showStartDialog(context, ref),
        icon: const Icon(Icons.playlist_add),
        label: const Text('Começar'),
      ),
    );
  }

  void _showStartDialog(BuildContext context, WidgetRef ref) {
    final repo = ref.read(workoutRepoProvider);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 8,
        ),
        child: FutureBuilder<List<Template>>(
          future: repo.listTemplates(),
          builder: (context, snap) {
            final templates = snap.data ?? [];
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Iniciar treino', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                FilledButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Criar treino do zero'),
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
