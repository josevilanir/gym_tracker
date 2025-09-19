// lib/features/workout/pages/history_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
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

  // calcula intervalo baseado no filtro atual
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
    final repo = ref.read(workoutRepoProvider);
    final (start, end) = _currentBounds();
    return repo.listFinishedWorkoutsBetween(start: start, end: end);
  }

  Future<List<({DateTime day, int volume})>> _loadDailyVolume() async {
    final repo = ref.read(workoutRepoProvider);
    final (start, end) = _currentBounds();
    return repo.dailyVolume(start: start, end: end);
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
          _QuickFilters(
            current: _range,
            onSelected: (r) => setState(() => _range = r),
          ),
          const SizedBox(height: 8),

          // -------- Gráfico + Lista (carregados em paralelo) --------
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
                        // CARD do gráfico
                        _VolumeChartCard(volumes: volumes),

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
                                final exCount = (s2.data != null && s2.data!.isNotEmpty)
                                    ? s2.data![0]
                                    : 0;
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

  const _ChipStat({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

// ------------- GRÁFICO DE VOLUME (CustomPaint) -------------

class _VolumeChartCard extends StatelessWidget {
  final List<({DateTime day, int volume})> volumes;
  const _VolumeChartCard({required this.volumes});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxV = volumes.isEmpty
        ? 0
        : volumes.map((e) => e.volume).reduce(math.max);
    final label = volumes.isEmpty
        ? 'Sem dados no período'
        : 'Volume por dia (${volumes.length}d)';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: CustomPaint(
                painter: _BarChartPainter(
                  data: volumes.map((e) => e.volume).toList(),
                  labels: volumes
                      .map((e) => DateFormat('dd/MM').format(e.day))
                      .toList(),
                  barColor: cs.primary,
                  axisColor: cs.outlineVariant,
                  textColor: Theme.of(context).textTheme.bodySmall?.color ??
                      cs.onSurfaceVariant,
                ),
                child: Container(),
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

  _BarChartPainter({
    required this.data,
    required this.labels,
    required this.barColor,
    required this.axisColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintAxis = Paint()
      ..color = axisColor
      ..strokeWidth = 1;

    final double leftPad = 28;
    final double bottomPad = 20;
    final double topPad = 8;
    final double rightPad = 8;

    final chartW = size.width - leftPad - rightPad;
    final chartH = size.height - topPad - bottomPad;

    // Eixos
    final origin = Offset(leftPad, size.height - bottomPad);
    canvas.drawLine(origin, Offset(size.width - rightPad, size.height - bottomPad), paintAxis);
    canvas.drawLine(origin, Offset(leftPad, topPad), paintAxis);

    if (data.isEmpty) return;

    final maxVal = data.reduce(math.max).toDouble();
    final barW = chartW / data.length * 0.6;
    final gap = (chartW / data.length - barW);

    final barPaint = Paint()..color = barColor;
    // ignore: prefer_function_declarations_over_variables
    final tp = (String s) {
      final ts = TextSpan(
        text: s,
        style: TextStyle(fontSize: 10, color: textColor),
      );
      final tp = TextPainter(
        text: ts,
        textDirection: ui.TextDirection.ltr, // ✅ usa enum do dart:ui
      );
      tp.layout();
      return tp;
    };

    for (int i = 0; i < data.length; i++) {
      final x = leftPad + i * (barW + gap) + gap / 2;
      final h = maxVal == 0 ? 0.0 : (data[i] / maxVal) * chartH;
      final rect = Rect.fromLTWH(x, origin.dy - h, barW, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        barPaint,
      );

      // labels X esparsas (mostra a cada ~max(1, n/7))
      final step = math.max(1, (data.length / 7).floor());
      if (i % step == 0 || i == data.length - 1) {
        final lbl = tp(labels[i]);
        final lx = x + barW / 2 - lbl.width / 2;
        final ly = size.height - bottomPad + 2;
        lbl.paint(canvas, Offset(lx, ly));
      }
    }

    // marca do valor máximo (texto pequeno no topo)
    final maxLbl = tp(maxVal.toInt().toString());
    maxLbl.paint(canvas, Offset(4, topPad - 2));
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.labels != labels ||
        oldDelegate.barColor != barColor ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.textColor != textColor;
  }
}
