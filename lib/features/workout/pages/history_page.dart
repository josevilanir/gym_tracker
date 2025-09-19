// lib/features/workout/pages/history_page.dart
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/providers.dart';
import '../../../data/db/app_database.dart';

enum _QuickRange { last7, last30, thisMonth, all, custom }
enum _Metric { sets, exercises }

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  _QuickRange _range = _QuickRange.last7;
  DateTimeRange? _customRange;

  _Metric _metric = _Metric.sets;

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

  /// Calcula série/exercício por dia AQUI (para não mexer no repositório).
  Future<List<({DateTime day, int volume})>> _loadDailyData() async {
    final repo = ref.read(workoutRepoProvider);
    final (start, end) = _currentBounds();

    // normaliza
    DateTime startDay = DateTime(start.year, start.month, start.day);
    DateTime endDay = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final workouts = await repo.listFinishedWorkoutsBetween(start: startDay, end: endDay);
    final Map<DateTime, int> perDay = {};

    for (final w in workouts) {
      final d = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
      final key = DateTime(d.year, d.month, d.day);
      int v;
      if (_metric == _Metric.sets) {
        v = await repo.countSetsInWorkout(w.id);
      } else {
        v = await repo.countExercisesInWorkout(w.id);
      }
      perDay.update(key, (old) => old + v, ifAbsent: () => v);
    }

    final days = <({DateTime day, int volume})>[];
    for (DateTime d = startDay; !d.isAfter(endDay); d = d.add(const Duration(days: 1))) {
      final key = DateTime(d.year, d.month, d.day);
      days.add((day: key, volume: perDay[key] ?? 0));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
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
      body: Column(
        children: [
          const SizedBox(height: 8),
          _QuickFilters(current: _range, onSelected: (r) => setState(() => _range = r)),
          const SizedBox(height: 8),

          // Toggle de métrica
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                ChoiceChip(
                  selected: _metric == _Metric.sets,
                  label: const Text('Séries'),
                  onSelected: (_) => setState(() => _metric = _Metric.sets),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  selected: _metric == _Metric.exercises,
                  label: const Text('Exercícios'),
                  onSelected: (_) => setState(() => _metric = _Metric.exercises),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: FutureBuilder<List<({DateTime day, int volume})>>(
              future: _loadDailyData(),
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
                        _VolumeChartCard(
                          title: _metric == _Metric.sets
                              ? 'Séries por dia'
                              : 'Exercícios por dia',
                          volumes: volumes,
                        ),
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
}

class _QuickFilters extends StatelessWidget {
  final _QuickRange current;
  final ValueChanged<_QuickRange> onSelected;

  const _QuickFilters({required this.current, required this.onSelected});

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

// ------------------- GRÁFICO COM TOOLTIP -------------------

class _VolumeChartCard extends StatefulWidget {
  final String title;
  final List<({DateTime day, int volume})> volumes;
  const _VolumeChartCard({required this.title, required this.volumes});

  @override
  State<_VolumeChartCard> createState() => _VolumeChartCardState();
}

class _VolumeChartCardState extends State<_VolumeChartCard> {
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final label = widget.volumes.isEmpty
        ? 'Sem dados no período'
        : '${widget.title} (${widget.volumes.length}d)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: LayoutBuilder(
                builder: (context, c) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) {
                      final idx = _BarChartPainter.hitTestIndex(
                        localPos: d.localPosition,
                        size: Size(c.maxWidth, 180),
                        dataLength: widget.volumes.length,
                      );
                      setState(() => _hoverIndex = idx);
                    },
                    child: CustomPaint(
                      painter: _BarChartPainter(
                        data: widget.volumes.map((e) => e.volume).toList(),
                        labels: widget.volumes
                            .map((e) => DateFormat('dd/MM').format(e.day))
                            .toList(),
                        barColor: cs.primary,
                        axisColor: cs.outlineVariant,
                        textColor: Theme.of(context).textTheme.bodySmall?.color ??
                            cs.onSurfaceVariant,
                        hoverIndex: _hoverIndex,
                        tooltipBg: cs.surfaceVariant,
                        tooltipFg: cs.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<int> data;
  final List<String> labels;
  final Color barColor;
  final Color axisColor;
  final Color textColor;
  final int? hoverIndex;
  final Color tooltipBg;
  final Color tooltipFg;

  _BarChartPainter({
    required this.data,
    required this.labels,
    required this.barColor,
    required this.axisColor,
    required this.textColor,
    this.hoverIndex,
    required this.tooltipBg,
    required this.tooltipFg,
  });

  static const double _leftPad = 28;
  static const double _bottomPad = 20;
  static const double _topPad = 8;
  static const double _rightPad = 8;

  static int? hitTestIndex({
    required Offset localPos,
    required Size size,
    required int dataLength,
  }) {
    final chartW = size.width - _leftPad - _rightPad;
    final barW = chartW / math.max(1, dataLength) * 0.6;
    final gap = (chartW / math.max(1, dataLength) - barW);
    for (int i = 0; i < dataLength; i++) {
      final x = _leftPad + i * (barW + gap) + gap / 2;
      final rect = Rect.fromLTWH(x, _topPad, barW, size.height - _topPad - _bottomPad);
      if (rect.contains(localPos)) return i;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintAxis = Paint()..color = axisColor..strokeWidth = 1;

    final chartW = size.width - _leftPad - _rightPad;
    final chartH = size.height - _topPad - _bottomPad;

    // Eixos
    final origin = Offset(_leftPad, size.height - _bottomPad);
    canvas.drawLine(origin, Offset(size.width - _rightPad, size.height - _bottomPad), paintAxis);
    canvas.drawLine(origin, Offset(_leftPad, _topPad), paintAxis);

    if (data.isEmpty) return;

    final maxVal = data.reduce(math.max).toDouble();
    final barW = chartW / data.length * 0.6;
    final gap = (chartW / data.length - barW);

    final barPaint = Paint()..color = barColor;
    TextPainter _tp(String s) {
      final ts = TextSpan(text: s, style: TextStyle(fontSize: 10, color: textColor));
      final tp = TextPainter(text: ts, textDirection: ui.TextDirection.ltr);
      tp.layout();
      return tp;
    }

    for (int i = 0; i < data.length; i++) {
      final x = _leftPad + i * (barW + gap) + gap / 2;
      final h = maxVal == 0 ? 0.0 : (data[i] / maxVal) * chartH; // double
      final rect = Rect.fromLTWH(x, origin.dy - h, barW, h);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), barPaint);

      // labels X (a cada ~n/7)
      final step = math.max(1, (data.length / 7).floor());
      if (i % step == 0 || i == data.length - 1) {
        final lbl = _tp(labels[i]);
        final lx = x + barW / 2 - lbl.width / 2;
        final ly = size.height - _bottomPad + 2;
        lbl.paint(canvas, Offset(lx, ly));
      }
    }

    // Tooltip simples
    if (hoverIndex != null && hoverIndex! >= 0 && hoverIndex! < data.length) {
      final i = hoverIndex!;
      final x = _leftPad + i * (barW + gap) + gap / 2 + barW / 2;
      final h = maxVal == 0 ? 0.0 : (data[i] / maxVal) * chartH;
      final y = origin.dy - h - 8;

      final txt = _tp(data[i].toString());
      final pad = 6.0;
      final r = RRect.fromLTRBR(
        x - txt.width / 2 - pad,
        y - txt.height - pad,
        x + txt.width / 2 + pad,
        y + pad,
        const Radius.circular(8),
      );
      final bg = Paint()..color = tooltipBg;
      canvas.drawRRect(r, bg);
      txt.paint(canvas, Offset(x - txt.width / 2, y - txt.height));
    }

    // valor máximo no topo
    final maxLbl = _tp(maxVal.toInt().toString());
    maxLbl.paint(canvas, const Offset(4, _topPad - 2));
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) {
    return old.data != data ||
        old.labels != labels ||
        old.barColor != barColor ||
        old.axisColor != axisColor ||
        old.textColor != textColor ||
        old.hoverIndex != hoverIndex ||
        old.tooltipBg != tooltipBg ||
        old.tooltipFg != tooltipFg;
  }
}
