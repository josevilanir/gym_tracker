// lib/features/workout/pages/history_page.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

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
        if (_customRange != null) return (_customRange!.start, _customRange!.end);
        return (now.subtract(const Duration(days: 6)), now);
    }
  }

  Future<List<Workout>> _loadWorkouts() async {
    final repo = ref.read(workoutRepoProvider);
    final (start, end) = _currentBounds();
    return repo.listFinishedWorkoutsBetween(start: start, end: end);
  }

  /// Volume diário simples (nº de séries) – inclui dias sem treino com zero
  Future<List<({DateTime day, int volume})>> _loadDailyVolume() async {
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
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acompanhamento'),
        actions: [
          IconButton(
            tooltip: 'Escolher intervalo…',
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final now = DateTime.now();
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(now.year - 2),
                lastDate: DateTime(now.year + 1),
                initialDateRange: _customRange ??
                    DateTimeRange(
                      start: DateTime(now.year, now.month, now.day)
                          .subtract(const Duration(days: 6)),
                      end: now,
                    ),
              );
              if (picked != null) {
                setState(() {
                  _range = _QuickRange.custom;
                  _customRange = picked;
                });
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Registrar treino'),
        onPressed: () => _openRegisterPastWorkout(context),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _QuickFilters(current: _range, onSelected: (r) => setState(() => _range = r)),
          const SizedBox(height: 8),
          Expanded(
            child: FutureBuilder<List<({DateTime day, int volume})>>(
              future: _loadDailyVolume(),
              builder: (context, volSnap) {
                return FutureBuilder<List<Workout>>(
                  future: _loadWorkouts(),
                  builder: (context, wSnap) {
                    if (volSnap.connectionState == ConnectionState.waiting ||
                        wSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final volumes = volSnap.data ?? const <({DateTime day, int volume})>[];
                    final workouts = wSnap.data ?? <Workout>[];

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _VolumeChartSimpleCard(volumes: volumes),
                        const SizedBox(height: 12),

                        if (workouts.isEmpty)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.history, size: 48, color: Colors.grey),
                                const SizedBox(height: 8),
                                Text(
                                  'Nenhum treino concluído no período selecionado.',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
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
                                final exCount =
                                    (s2.data != null && s2.data!.isNotEmpty) ? s2.data![0] : 0;
                                final setCount = (s2.data != null && s2.data!.length > 1)
                                    ? s2.data![1]
                                    : 0;

                                final date =
                                    DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
                                final dateStr =
                                    DateFormat('dd/MM, HH:mm').format(date);
                                final title = (w.title?.trim().isNotEmpty ?? false)
                                    ? w.title!
                                    : 'Treino sem nome';

                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    title: Text(title),
                                    subtitle: Text('Concluído em $dateStr'),
                                    trailing: Wrap(
                                      spacing: 8,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        _ChipStat(
                                            icon: Icons.fitness_center,
                                            label: '$exCount'),
                                        _ChipStat(
                                            icon: Icons.format_list_numbered,
                                            label: '$setCount'),
                                      ],
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

    DateTime selected = DateTime(now.year, now.month, now.day, now.hour, now.minute);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        final titleCtrl = TextEditingController();

        return Padding(
          padding: MediaQuery.of(ctx).viewInsets.add(const EdgeInsets.all(16)),
          child: FutureBuilder<List<Template>>(
            future: repo.listTemplates(),
            builder: (context, snap) {
              final templates = snap.data ?? [];

              return StatefulBuilder(
                builder: (context, setLocal) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Registrar treino em outra data',
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),

                        TextField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Título (opcional)',
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Seletor de data/hora
                        ListTile(
                          leading: const Icon(Icons.event),
                          title: Text(DateFormat('dd/MM/yyyy – HH:mm').format(selected)),
                          subtitle: const Text('Toque para alterar data e hora'),
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(now.year - 2),
                              lastDate: DateTime(now.year + 1),
                              initialDate: selected,
                            );
                            if (d == null) return;
                            final t = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(selected),
                            );
                            setLocal(() {
                              selected = DateTime(
                                d.year, d.month, d.day,
                                t?.hour ?? selected.hour,
                                t?.minute ?? selected.minute,
                              );
                            });
                          },
                        ),

                        const SizedBox(height: 16),
                        Text('Começar usando uma rotina?', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),

                        if (templates.isEmpty)
                          const Text('Nenhuma rotina salva. Você pode registrar um treino vazio.')
                        else
                          ...templates.map((t) => ListTile(
                                leading: const Icon(Icons.bookmark_added_outlined),
                                title: Text(t.name),
                                trailing: TextButton(
                                  child: const Text('Usar'),
                                  onPressed: () async {
                                    final wid = await repo.createWorkoutFromTemplateAt(
                                      templateId: t.id,
                                      date: selected,
                                      title: titleCtrl.text.trim().isEmpty ? t.name : titleCtrl.text.trim(),
                                      done: true, // registro retroativo normalmente já concluído
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      context.pushNamed('workout_detail', pathParameters: {'id': wid});
                                    }
                                  },
                                ),
                              )),

                        const Divider(height: 24),

                        FilledButton.icon(
                          icon: const Icon(Icons.playlist_add),
                          label: const Text('Registrar treino vazio nessa data'),
                          onPressed: () async {
                            final wid = await repo.createWorkoutAt(
                              date: selected,
                              title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                              done: true,
                            );
                            if (context.mounted) {
                              Navigator.pop(context);
                              context.pushNamed('workout_detail', pathParameters: {'id': wid});
                            }
                          },
                        ),
                      ],
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
  }
}

// ---------- componentes auxiliares (mantidos do dia anterior) ----------

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
    return Chip(avatar: Icon(icon, size: 18), label: Text(label));
  }
}

// --------- Gráfico simples (layout por Row/Expanded) ---------

class _VolumeChartSimpleCard extends StatelessWidget {
  final List<({DateTime day, int volume})> volumes;
  const _VolumeChartSimpleCard({required this.volumes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final values = volumes.map((e) => e.volume).toList();
    final labels = volumes.map((e) => DateFormat('dd/MM').format(e.day)).toList();
    final title = 'Séries por dia (${volumes.length}d)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: _BarsRow(
                values: values,
                labels: labels,
                barColor: cs.primary,
                textColor: Theme.of(context).textTheme.bodySmall?.color ?? cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarsRow extends StatelessWidget {
  final List<int> values;
  final List<String> labels;
  final Color barColor;
  final Color textColor;

  const _BarsRow({
    required this.values,
    required this.labels,
    required this.barColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) {
      return const Center(child: Text('Sem dados no período'));
    }

    final maxVal = values.reduce((a, b) => a > b ? a : b);
    final n = values.length;

    // --- rótulos: no máx. 4 datas distribuídas (início/meio/fim) ---
    final maxLabels = n <= 4 ? n : 4;
    final Set<int> labelIdxs = {};
    if (n == 1) {
      labelIdxs.add(0);
    } else {
      for (int i = 0; i < maxLabels; i++) {
        final idx = ((i * (n - 1)) / (maxLabels - 1)).round();
        labelIdxs.add(idx);
      }
    }

    // --- largura das barras dentro do slot: dá respiro lateral ---
    double widthFactor;
    if (n <= 6) {
      widthFactor = 0.55;
    } else if (n <= 12) {
      widthFactor = 0.42;
    } else if (n <= 20) {
      widthFactor = 0.34;
    } else {
      widthFactor = 0.28;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(n, (i) {
        final v = values[i];
        final hFactor = maxVal == 0 ? 0.0 : (v / maxVal);

        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Barra
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    widthFactor: widthFactor,
                    heightFactor: hFactor,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              // Rótulo (somente para alguns índices) com leve rotação
              SizedBox(
                height: 18,
                child: Center(
                  child: labelIdxs.contains(i)
                      ? Transform.rotate(
                          angle: -0.45, // ~-26°
                          child: Text(
                            labels[i],
                            style: TextStyle(fontSize: 9, color: textColor),
                            overflow: TextOverflow.visible,
                            softWrap: false,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}