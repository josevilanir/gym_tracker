import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators.dart';
import '../../../core/constants.dart';
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
            tooltip: 'Progresso',
            onPressed: () => context.pushNamed('progress'),
            icon: const Icon(Icons.bar_chart_rounded),
          ),
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
        error: (e, _) => Center(
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
                  'Erro ao preparar app',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
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
                    'Erro ao carregar treinos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

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

            if (metricsSnap.hasError) {
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
                        'Erro ao carregar métricas',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${metricsSnap.error}',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
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
                  Center(
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
                          'Sem treinos ativos',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Crie um treino vazio ou use uma rotina salva',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  final title = (w.title?.trim().isNotEmpty ?? false)
                      ? w.title!
                      : 'Treino sem nome';

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center),
                      title: Text(title),
                      subtitle: Text('Iniciado em $dateStr'),
                      trailing: IconButton(
                        tooltip: 'Concluir',
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () async {
                          try {
                            await repo.markDone(w.id, true);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.white),
                                      SizedBox(width: 12),
                                      Text('Treino concluído!'),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  duration: AppConstants.snackBarSuccessDuration,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.error_outline, color: Colors.white),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text('Erro ao concluir treino: $e')),
                                    ],
                                  ),
                                  backgroundColor: Theme.of(context).colorScheme.error,
                                  behavior: SnackBarBehavior.floating,
                                  duration: AppConstants.snackBarErrorDuration,
                                ),
                              );
                            }
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
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: onColor),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: onColor),
        ),
      ],
    );
  }
}

class _StartFab extends ConsumerStatefulWidget {
  final bool inline;
  const _StartFab({this.inline = false});

  @override
  ConsumerState<_StartFab> createState() => _StartFabState();
}

class _StartFabState extends ConsumerState<_StartFab> {
  Future<String?> _askWorkoutTitle(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Título do treino'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: ctrl,
                decoration: InputDecoration(
                  labelText: 'Título (opcional)',
                  hintText: 'Ex: Treino de pernas leve',
                  helperText: 'Deixe vazio para título automático',
                  prefixIcon: const Icon(Icons.title),
                  counterText:
                      '${ctrl.text.length}/${AppConstants.maxWorkoutTitleLength}',
                ),
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                maxLength: AppConstants.maxWorkoutTitleLength,
                validator: Validators.workoutTitle,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (_) => setState(() {}), // atualiza contador
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  final value = ctrl.text.trim();

                  // Se vazio, permite (título é opcional)
                  if (value.isEmpty) {
                    Navigator.pop(ctx, '');
                    return;
                  }

                  // Se preenchido, valida
                  final error = Validators.workoutTitle(value);
                  if (error != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(error),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  Navigator.pop(ctx, value);
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStartDialog(BuildContext context) {
    final repo = ref.read(workoutRepoProvider);

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: FutureBuilder<List<Template>>(
          future: repo.listTemplates(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snap.hasError) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar rotinas',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${snap.error}',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            final templates = snap.data ?? [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Iniciar treino',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),

                // 1) Treino vazio / personalizado
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.playlist_add),
                    title: const Text('Treino vazio / personalizado'),
                    subtitle: const Text('Começar agora, sem rotina'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      try {
                        final title = await _askWorkoutTitle(context);
                        if (title == null) return; // cancelou

                        final id = await repo.createEmptyWorkoutNow(
                          title: title.trim().isEmpty ? null : title.trim(),
                        );

                        if (!context.mounted) return;
                        Navigator.pop(ctx); // fecha o bottom sheet
                        context.pushNamed(
                          'workout_detail',
                          pathParameters: {'id': id},
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.white),
                                const SizedBox(width: 12),
                                Expanded(child: Text('Erro ao criar treino: $e')),
                              ],
                            ),
                            backgroundColor: Theme.of(context).colorScheme.error,
                            behavior: SnackBarBehavior.floating,
                            duration: AppConstants.snackBarErrorDuration,
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // 2) Iniciar a partir de rotina existente
                Text(
                  'Usar rotina salva',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                if (templates.isEmpty)
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.bookmark_add_outlined,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.5),
                      ),
                      title: const Text('Nenhuma rotina salva'),
                      subtitle: const Text('Crie uma rotina para usá-la aqui'),
                      onTap: () {
                        Navigator.pop(ctx);
                        context.pushNamed('workout_new');
                      },
                    ),
                  )
                else
                  ...templates.map(
                    (t) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.bookmark_outlined),
                        title: Text(t.name),
                        subtitle: const Text('Começar agora a partir desta rotina'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          try {
                            final newId = await repo.createWorkoutFromTemplateAt(
                              templateId: t.id,
                              date: DateTime.now(),
                              title: t.name,
                              done: false, // ativo
                            );

                            if (!context.mounted) return;
                            Navigator.pop(ctx);
                            context.pushNamed(
                              'workout_detail',
                              pathParameters: {'id': newId},
                            );
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.error_outline,
                                        color: Colors.white),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Erro ao criar treino da rotina: $e',
                                      ),
                                    ),
                                  ],
                                ),
                                backgroundColor:
                                    Theme.of(context).colorScheme.error,
                                behavior: SnackBarBehavior.floating,
                                duration: AppConstants.snackBarErrorDuration,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // 3) Atalho para criar/editar rotinas
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.pushNamed('workout_new');
                  },
                  icon: const Icon(Icons.auto_awesome_motion_outlined),
                  label: const Text('Criar/editar rotinas'),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.inline
          ? EdgeInsets.zero
          : const EdgeInsets.only(bottom: 8, right: 8),
      child: FloatingActionButton.extended(
        heroTag: widget.inline ? 'start_inline' : 'start_fab',
        onPressed: () => _showStartDialog(context),
        icon: const Icon(Icons.playlist_add),
        label: const Text('Começar'),
      ),
    );
  }
}