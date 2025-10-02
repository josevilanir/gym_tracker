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
      stream: repo.watchActiveWorkouts(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];

        return FutureBuilder(
          future: Future.wait([
            repo.countWorkoutsThisMonth(),
            repo.getTrainingStreak(),
            repo.countExercisesThisMonth(),
          ]),
          builder: (context, AsyncSnapshot<List<int>> metricsSnap) {
            if (metricsSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final metrics = metricsSnap.data ?? [0, 0, 0];
            final workoutsMonth = metrics[0];
            final streak = metrics[1];
            final volumeMonth = metrics[2];

            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header de métricas mesmo sem treino ativo
                  _MetricsHeader(
                    workoutsMonth: workoutsMonth,
                    streak: streak,
                    volumeMonth: volumeMonth,
                  ),
                  const SizedBox(height: 32),
                  const Center(child: Text('Sem treinos ativos.')),
                  const SizedBox(height: 8),
                  const Center(child: Text('Crie um treino vazio ou use uma rotina salva.')),
                  const SizedBox(height: 16),
                  const Center(child: _StartFab(inline: true)),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _MetricsHeader(
                  workoutsMonth: workoutsMonth,
                  streak: streak,
                  volumeMonth: volumeMonth,
                ),
                const SizedBox(height: 12),
                ...items.map((w) {
                  final date = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
                  final dateStr = DateFormat('dd/MM, HH:mm').format(date);
                  final title =
                      (w.title?.trim().isNotEmpty ?? false) ? w.title! : 'Treino sem nome';

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(title),
                      subtitle: Text('Iniciado em $dateStr'),
                      trailing: IconButton(
                        tooltip: 'Concluir',
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () async {
                          await repo.markDone(w.id, true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Treino concluído!')),
                            );
                          }
                        },
                      ),
                      onTap: () => context.pushNamed(
                        'workout_detail',
                        pathParameters: {'id': w.id},
                      ),
                    ),
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }
}

/// Widget de header de métricas
class _MetricsHeader extends StatelessWidget {
  final int workoutsMonth;
  final int streak;
  final int volumeMonth;

  const _MetricsHeader({
    required this.workoutsMonth,
    required this.streak,
    required this.volumeMonth,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primaryContainer;
    final onColor = Theme.of(context).colorScheme.onPrimaryContainer;

    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _MetricItem(
              label: 'Treinos no mês',
              value: workoutsMonth.toString(),
              onColor: onColor,
            ),
            _MetricItem(
              label: 'Streak',
              value: '${streak}d',
              onColor: onColor,
            ),
            _MetricItem(
              label: 'Exercícios no mês',
              value: volumeMonth.toString(),
              onColor: onColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color onColor;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: onColor)),
        const SizedBox(height: 4),
        Text(label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onColor)),
      ],
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
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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

                // 1) Treino vazio / personalizado
                ListTile(
                  leading: const Icon(Icons.playlist_add),
                  title: const Text('Treino vazio / personalizado'),
                  subtitle: const Text('Começar agora, sem rotina'),
                  onTap: () async {
                    final id = await repo.createEmptyWorkoutNow(); // done:false (ativo)
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    context.pushNamed('workout_detail', pathParameters: {'id': id});
                  },
                ),

                const Divider(height: 16),

                // 2) Iniciar a partir de rotina existente
                Text('Usar rotina salva', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                if (templates.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.bookmark_add_outlined),
                    title: Text('Nenhuma rotina salva'),
                    subtitle: Text('Crie uma rotina para usá-la aqui'),
                  )
                else
                  ...templates.map(
                    (t) => ListTile(
                      leading: const Icon(Icons.bookmark_outlined),
                      title: Text(t.name),
                      subtitle: const Text('Começar agora a partir desta rotina'),
                      onTap: () async {
                        final newId = await repo.createWorkoutFromTemplateAt(
                          templateId: t.id,
                          date: DateTime.now(),
                          title: t.name,
                          done: false, // ativo
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        context.pushNamed('workout_detail', pathParameters: {'id': newId});
                      },
                    ),
                  ),

                const SizedBox(height: 8),
                // 3) Atalho para criar/editar rotinas (não cria treino!)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.pushNamed('workout_new'); // abre o editor de rotina
                  },
                  icon: const Icon(Icons.auto_awesome_motion_outlined),
                  label: const Text('Criar/editar rotinas'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
