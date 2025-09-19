// lib/features/workout/pages/history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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

  Future<List<Workout>> _load(WidgetRef ref) async {
    final repo = ref.read(workoutRepoProvider);
    final now = DateTime.now();

    DateTime start;
    DateTime end;

    switch (_range) {
      case _QuickRange.last7:
        start = now.subtract(const Duration(days: 6));
        end = now;
        break;
      case _QuickRange.last30:
        start = now.subtract(const Duration(days: 29));
        end = now;
        break;
      case _QuickRange.thisMonth:
        final b = repo.monthBounds(now);
        start = DateTime.fromMillisecondsSinceEpoch(b.startEpoch);
        end = DateTime.fromMillisecondsSinceEpoch(b.endEpoch);
        break;
      case _QuickRange.all:
        // intervalo “infinito” prático
        start = DateTime(2000, 1, 1);
        end = now;
        break;
      case _QuickRange.custom:
        if (_customRange == null) {
          // se não tiver custom ainda, volta pros últimos 7
          start = now.subtract(const Duration(days: 6));
          end = now;
        } else {
          start = _customRange!.start;
          end = _customRange!.end;
        }
        break;
    }

    return repo.listFinishedWorkoutsBetween(start: start, end: end);
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
                      start: DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)),
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
          Expanded(
            child: FutureBuilder<List<Workout>>(
              future: _load(ref),
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
                        const Icon(Icons.history, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text(
                          'Nenhum treino concluído no período selecionado.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ajuste os filtros para visualizar outros treinos.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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
                    return FutureBuilder(
                      future: Future.wait([
                        repo.countExercisesInWorkout(w.id),
                        repo.countSetsInWorkout(w.id),
                      ]),
                      builder: (context, AsyncSnapshot<List<int>> s2) {
                        final exCount = (s2.data != null && s2.data!.isNotEmpty) ? s2.data![0] : 0;
                        final setCount = (s2.data != null && s2.data!.length > 1) ? s2.data![1] : 0;

                        final date = DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
                        final dateStr = DateFormat('dd/MM, HH:mm').format(date);
                        final title =
                            (w.title?.trim().isNotEmpty ?? false) ? w.title! : 'Treino sem nome';

                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.check_circle, color: Colors.green),
                            title: Text(title),
                            subtitle: Text('Concluído em $dateStr'),
                            trailing: Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _ChipStat(icon: Icons.fitness_center, label: '$exCount'),
                                _ChipStat(icon: Icons.format_list_numbered, label: '$setCount'),
                              ],
                            ),
                          ),
                        );
                      },
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
