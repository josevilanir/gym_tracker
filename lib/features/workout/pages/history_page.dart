import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../core/validators.dart';
import '../../../core/constants.dart';
import '../controllers/providers.dart';
import '../../../data/db/app_database.dart';

enum _QuickRange { last7, last30, thisMonth, all, custom }

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  _QuickRange _range = _QuickRange.last7;
  DateTimeRange? _customRange;

  (DateTime start, DateTime end) _currentBounds() {
    final now = DateTime.now();
    switch (_range) {
      case _QuickRange.last7:
        return (now.subtract(const Duration(days: 6)), now);
      case _QuickRange.last30:
        return (now.subtract(const Duration(days: 29)), now);
      case _QuickRange.thisMonth:
        final repo = ref.read(workoutRepoProvider);
        final b = repo.monthBounds(now);
        return (
          DateTime.fromMillisecondsSinceEpoch(b.startEpoch),
          DateTime.fromMillisecondsSinceEpoch(b.endEpoch),
        );
      case _QuickRange.all:
        return (DateTime(2000, 1, 1), now);
      case _QuickRange.custom:
        if (_customRange != null) {
          return (_customRange!.start, _customRange!.end);
        }
        return (now.subtract(const Duration(days: 6)), now);
    }
  }

  Future<List<Workout>> _loadWorkouts() async {
    try {
      final repo = ref.read(workoutRepoProvider);
      final (start, end) = _currentBounds();
      return await repo.listFinishedWorkoutsBetween(start: start, end: end);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao carregar treinos: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            duration: AppConstants.snackBarErrorDuration,
          ),
        );
      }
      rethrow;
    }
  }

  /// Volume diário simples (nº de séries) – inclui dias sem treino com zero
  Future<List<({DateTime day, int volume})>> _loadDailyVolume() async {
    try {
      final repo = ref.read(workoutRepoProvider);
      final (start, end) = _currentBounds();

      final startDay = DateTime(start.year, start.month, start.day);
      final endDay = DateTime(end.year, end.month, end.day);

      final workouts = await repo.listFinishedWorkoutsBetween(
        start: startDay,
        end: DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59),
      );

      final Map<DateTime, int> perDay = {};
      for (final w in workouts) {
        final d = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
        final key = DateTime(d.year, d.month, d.day);
        final sets = await repo.countSetsInWorkout(w.id);
        perDay.update(key, (old) => old + sets, ifAbsent: () => sets);
      }

      final totalDays = endDay.difference(startDay).inDays + 1;
      return List.generate(totalDays, (i) {
        final d = DateTime(startDay.year, startDay.month, startDay.day + i);
        final key = DateTime(d.year, d.month, d.day);
        return (day: d, volume: perDay[key] ?? 0);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Erro ao carregar gráfico: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [
          IconButton(
            tooltip: 'Registrar treino retroativo',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _openRegisterPastWorkout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros rápidos
          _QuickFilters(
            current: _range,
            onSelected: (r) async {
              if (r == _QuickRange.custom) {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(DateTime.now().year - 2),
                  lastDate: DateTime.now(),
                  initialDateRange: _customRange,
                );
                if (picked != null) {
                  setState(() {
                    _customRange = picked;
                    _range = r;
                  });
                }
              } else {
                setState(() => _range = r);
              }
            },
          ),
          const SizedBox(height: 8),

          // Conteúdo principal
          Expanded(
            child: FutureBuilder<List<({DateTime day, int volume})>>(
              future: _loadDailyVolume(),
              builder: (context, vSnap) {
                if (vSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (vSnap.hasError) {
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
                            'Erro ao carregar dados',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${vSnap.error}',
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

                final volumes = vSnap.data ?? const <({DateTime day, int volume})>[];

                return FutureBuilder<List<Workout>>(
                  future: _loadWorkouts(),
                  builder: (context, wSnap) {
                    if (wSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (wSnap.hasError) {
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
                                '${wSnap.error}',
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

                    final workouts = wSnap.data ?? <Workout>[];

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Gráfico de volume
                        _VolumeChartSimpleCard(volumes: volumes),
                        const SizedBox(height: 12),

                        // Lista de treinos ou empty state
                        if (workouts.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.history,
                                    size: 80,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Nenhum treino concluído',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Nenhum treino concluído no período selecionado',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  FilledButton.icon(
                                    onPressed: () =>
                                        _openRegisterPastWorkout(context),
                                    icon: const Icon(Icons.add),
                                    label: const Text('Registrar treino'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...workouts.map((w) {
                            return FutureBuilder(
                              future: Future.wait([
                                repo.countExercisesInWorkout(w.id),
                                repo.countSetsInWorkout(w.id),
                              ]),
                              builder: (context, AsyncSnapshot<List<int>> s2) {
                                if (s2.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Card(
                                    child: ListTile(
                                      leading: CircularProgressIndicator(),
                                      title: Text('Carregando...'),
                                    ),
                                  );
                                }

                                final exCount = (s2.data != null &&
                                        s2.data!.isNotEmpty)
                                    ? s2.data![0]
                                    : 0;
                                final setCount = (s2.data != null &&
                                        s2.data!.length > 1)
                                    ? s2.data![1]
                                    : 0;

                                final date = DateTime.fromMillisecondsSinceEpoch(
                                    w.dateEpoch);
                                final dateStr =
                                    DateFormat('dd/MM, HH:mm').format(date);
                                final title =
                                    (w.title?.trim().isNotEmpty ?? false)
                                        ? w.title!
                                        : 'Treino sem nome';

                                return Card(
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                    ),
                                    title: Text(title),
                                    subtitle: Text('Concluído em $dateStr'),
                                    trailing: Wrap(
                                      spacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        _ChipStat(
                                          icon: Icons.fitness_center,
                                          label: '$exCount',
                                        ),
                                        _ChipStat(
                                          icon: Icons.format_list_numbered,
                                          label: '$setCount',
                                        ),
                                      ],
                                    ),
                                    onTap: () => context.pushNamed(
                                      'history_workout_detail',
                                      pathParameters: {'id': w.id},
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openRegisterPastWorkout(BuildContext context) async {
    final repo = ref.read(workoutRepoProvider);
    final now = DateTime.now();
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController();

    DateTime selected = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
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
                        ],
                      ),
                    ),
                  );
                }

                final templates = snap.data ?? [];

                return StatefulBuilder(
                  builder: (context, setLocal) {
                    return SingleChildScrollView(
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Registrar treino em outra data',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),

                            // Campo de título com validação
                            TextFormField(
                              controller: titleCtrl,
                              decoration: InputDecoration(
                                labelText: 'Título (opcional)',
                                hintText: 'Ex: Treino de pernas intenso',
                                prefixIcon: const Icon(Icons.title),
                                helperText: 'Deixe vazio para título automático',
                                counterText:
                                    '${titleCtrl.text.length}/${AppConstants.maxWorkoutTitleLength}',
                              ),
                              textCapitalization: TextCapitalization.sentences,
                              maxLength: AppConstants.maxWorkoutTitleLength,
                              validator: Validators.workoutTitle,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              onChanged: (_) => setLocal(() {}),
                            ),
                            const SizedBox(height: 12),

                            // Seletor de data/hora
                            Card(
                              child: ListTile(
                                leading: const Icon(Icons.event),
                                title: Text(
                                  DateFormat('dd/MM/yyyy – HH:mm')
                                      .format(selected),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Toque para alterar data e hora',
                                ),
                                trailing: const Icon(Icons.edit),
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(now.year - 2),
                                    lastDate: DateTime(now.year + 1),
                                    initialDate: selected,
                                  );
                                  if (d == null) return;

                                  if (!context.mounted) return;
                                  final t = await showTimePicker(
                                    context: context,
                                    initialTime:
                                        TimeOfDay.fromDateTime(selected),
                                  );

                                  setLocal(() {
                                    selected = DateTime(
                                      d.year,
                                      d.month,
                                      d.day,
                                      t?.hour ?? selected.hour,
                                      t?.minute ?? selected.minute,
                                    );
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Seleção de template
                            Text(
                              'Começar usando uma rotina?',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),

                            if (templates.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.bookmark_add_outlined,
                                        size: 48,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Nenhuma rotina salva',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Você pode registrar um treino vazio',
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ...templates.map((t) => Card(
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.bookmark_outlined,
                                      ),
                                      title: Text(t.name),
                                      trailing: TextButton(
                                        child: const Text('Usar'),
                                        onPressed: () async {
                                          try {
                                            // Valida título se preenchido
                                            final titleValue =
                                                titleCtrl.text.trim();
                                            if (titleValue.isNotEmpty) {
                                              final error =
                                                  Validators.workoutTitle(
                                                      titleValue);
                                              if (error != null) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(error),
                                                    backgroundColor:
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .error,
                                                  ),
                                                );
                                                return;
                                              }
                                            }

                                            final wid = await repo
                                                .createWorkoutFromTemplateAt(
                                              templateId: t.id,
                                              date: selected,
                                              title: titleValue.isEmpty
                                                  ? t.name
                                                  : titleValue,
                                              done: false,
                                            );

                                            if (!context.mounted) return;
                                            Navigator.pop(context);
                                            context.pushNamed(
                                              'workout_detail',
                                              pathParameters: {'id': wid},
                                            );
                                          } catch (e) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.error_outline,
                                                      color: Colors.white,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'Erro ao criar treino: $e',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .error,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  )),

                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 16),

                            // Botão de registrar treino vazio
                            FilledButton.icon(
                              icon: const Icon(Icons.playlist_add),
                              label: const Text('Registrar treino nessa data'),
                              onPressed: () async {
                                try {
                                  // Valida título se preenchido
                                  final titleValue = titleCtrl.text.trim();
                                  if (titleValue.isNotEmpty) {
                                    final error =
                                        Validators.workoutTitle(titleValue);
                                    if (error != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .error,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                      return;
                                    }
                                  }

                                  final wid = await repo.createWorkoutAt(
                                    date: selected,
                                    title: titleValue.isEmpty
                                        ? null
                                        : titleValue,
                                    done: false,
                                  );

                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                  context.pushNamed(
                                    'workout_detail',
                                    pathParameters: {'id': wid},
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              'Erro ao criar treino: $e',
                                            ),
                                          ),
                                        ],
                                      ),
                                      backgroundColor:
                                          Theme.of(context).colorScheme.error,
                                      behavior: SnackBarBehavior.floating,
                                      duration:
                                          AppConstants.snackBarErrorDuration,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      );

      setState(() {}); // atualiza a lista/gráfico depois do cadastro
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Erro ao abrir formulário: $e')),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// ========== COMPONENTES AUXILIARES ==========

class _QuickFilters extends StatelessWidget {
  final _QuickRange current;
  final ValueChanged<_QuickRange> onSelected;

  const _QuickFilters({
    required this.current,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (label: '7 dias', value: _QuickRange.last7),
      (label: '30 dias', value: _QuickRange.last30),
      (label: 'Este mês', value: _QuickRange.thisMonth),
      (label: 'Tudo', value: _QuickRange.all),
      (label: 'Intervalo…', value: _QuickRange.custom),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: items.map((e) {
          final selected = e.value == current;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(e.label),
              selected: selected,
              onSelected: (_) => onSelected(e.value),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ChipStat({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _VolumeChartSimpleCard extends StatelessWidget {
  final List<({DateTime day, int volume})> volumes;

  const _VolumeChartSimpleCard({required this.volumes});

  @override
  Widget build(BuildContext context) {
    if (volumes.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'Sem dados no período',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final maxVol = volumes.map((v) => v.volume).reduce((a, b) => a > b ? a : b);
    if (maxVol == 0) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 8),
              const Text('Nenhum treino registrado no período'),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Volume de séries por dia',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 67,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: volumes.map((v) {
                  final heightFactor = maxVol > 0 ? v.volume / maxVol : 0.0;
                  final barHeight = 50 * heightFactor;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (v.volume > 0)
                            Text(
                              '${v.volume}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 9,
                                height: 1.0,
                              ),
                            ),
                          Container(
                            height: barHeight < 4 && v.volume > 0 ? 4 : barHeight,
                            decoration: BoxDecoration(
                              color: v.volume > 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Text(
                            DateFormat('dd/MM').format(v.day),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 8,
                              height: 1.0,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${volumes.fold<int>(0, (sum, v) => sum + v.volume)} séries',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
                Text(
                  'Máx: $maxVol séries/dia',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}