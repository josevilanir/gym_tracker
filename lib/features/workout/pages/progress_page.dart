import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../controllers/providers.dart';

/// Página de Estatísticas / Progresso do usuário.
/// - Cards de métricas do mês (treinos, exercícios, streak)
/// - Gráfico simples de séries por dia (7d / 30d / mês atual)
/// - Top exercícios por volume (nº de séries) no período selecionado
class ProgressPage extends ConsumerStatefulWidget {
  const ProgressPage({super.key});

  @override
  ConsumerState<ProgressPage> createState() => _ProgressPageState();
}

enum _Range { d7, d30, month }

class _ProgressPageState extends ConsumerState<ProgressPage> {
  _Range range = _Range.d7;

  DateTime _startForRange(DateTime now) {
    switch (range) {
      case _Range.d7:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
      case _Range.d30:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 29));
      case _Range.month:
        return DateTime(now.year, now.month, 1);
    }
  }

  DateTime _endForRange(DateTime now) {
    switch (range) {
      case _Range.d7:
      case _Range.d30:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case _Range.month:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    final header = FutureBuilder<List<int>>(
      future: Future.wait([
        repo.countWorkoutsThisMonth(),
        repo.getTrainingStreak(),
        repo.countExercisesThisMonth(),
      ]),
      builder: (context, snap) {
        final m = snap.data ?? const [0, 0, 0];
        return _MetricsHeader(
          workoutsMonth: m[0],
          streak: m[1],
          volumeMonth: m[2],
        );
      },
    );

    final now = DateTime.now();
    final start = _startForRange(now);
    final end = _endForRange(now);

    // Volume diário (nº de séries) no período
    final chart = FutureBuilder<List<({DateTime day, int volume})>>(
      future: repo.dailyVolume(start: start, end: end),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 140,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final data = snap.data ?? const <({DateTime day, int volume})>[];
        return _BarChartDaily(data: data);
      },
    );

    // Top exercícios por volume (séries) no período
    final topExercises = FutureBuilder<List<_ExerciseVolume>>(
      future: _computeTopExercises(ref, start, end),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(),
          ));
        }
        final items = snap.data ?? const <_ExerciseVolume>[];
        if (items.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Text('Sem exercícios concluídos no período.'),
          );
        }
        return Column(
          children: items.map((e) {
            return ListTile(
              leading: CircleAvatar(child: Text('${e.rank}')),
              title: Text(e.exerciseName),
              subtitle: Text('${e.sets} série(s) no período'),
            );
          }).toList(),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progresso'),
        actions: [
          PopupMenuButton<_Range>(
            initialValue: range,
            onSelected: (r) => setState(() => range = r),
            itemBuilder: (context) => const [
              PopupMenuItem(value: _Range.d7,  child: Text('Últimos 7 dias')),
              PopupMenuItem(value: _Range.d30, child: Text('Últimos 30 dias')),
              PopupMenuItem(value: _Range.month, child: Text('Mês atual')),
            ],
            icon: const Icon(Icons.filter_list),
            tooltip: 'Intervalo',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          header,
          const SizedBox(height: 16),

          // Título do gráfico + legenda do período
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Séries por dia',
                  style: Theme.of(context).textTheme.titleMedium),
              Text('${DateFormat('dd/MM').format(start)} – ${DateFormat('dd/MM').format(end)}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 8),
          chart,

          const SizedBox(height: 24),
          Text('Top exercícios por volume',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          topExercises,
        ],
      ),
    );
  }

  /// Agrega os exercícios com base em nº de séries no período selecionado.
  Future<List<_ExerciseVolume>> _computeTopExercises(
    WidgetRef ref,
    DateTime start,
    DateTime end,
  ) async {
    final repo = ref.read(workoutRepoProvider);

    // 1) Buscar treinos concluídos no período
    final workouts = await repo.listFinishedWorkoutsBetween(start: start, end: end);
    if (workouts.isEmpty) return const [];

    // 2) Para cada treino, listar exercícios e sets; agregar por exercício (nome)
    final Map<String, int> setsByExerciseName = {};
    for (final w in workouts) {
      final wes = await repo.listWorkoutExercises(w.id);
      for (final we in wes) {
        final sets = await repo.listSets(we.id);
        if (sets.isEmpty) continue;
        final ex = await repo.getExercise(we.exerciseId);
        final name = ex?.name ?? 'Exercício';
        setsByExerciseName.update(name, (old) => old + sets.length, ifAbsent: () => sets.length);
      }
    }

    // 3) Ordenar por nº de séries e retornar Top 10
    final sorted = setsByExerciseName.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(10).toList();
    final list = <_ExerciseVolume>[];
    for (var i = 0; i < top.length; i++) {
      list.add(_ExerciseVolume(rank: i + 1, exerciseName: top[i].key, sets: top[i].value));
    }
    return list;
  }
}

/// Modelo simples para ranking de exercícios por séries
class _ExerciseVolume {
  final int rank;
  final String exerciseName;
  final int sets;
  const _ExerciseVolume({required this.rank, required this.exerciseName, required this.sets});
}

/// Header de métricas do mês
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
            _MetricItem(label: 'Treinos no mês', value: '$workoutsMonth', onColor: onColor),
            _MetricItem(label: 'Streak', value: '${streak}d', onColor: onColor),
            _MetricItem(label: 'Exercícios no mês', value: '$volumeMonth', onColor: onColor),
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

/// Gráfico de barras simples (sem libs) para séries por dia.
/// Cada barra representa um dia do período.
class _BarChartDaily extends StatelessWidget {
  final List<({DateTime day, int volume})> data;
  const _BarChartDaily({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Sem dados no período.')),
      );
    }

    final maxV = max(1, data.map((e) => e.volume).fold<int>(0, max));
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((d) {
          final h = (d.volume / maxV) * 100.0; // altura relativa
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Tooltip(
                  message: '${DateFormat('dd/MM').format(d.day)} — ${d.volume} série(s)',
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: max(4, h),
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(DateFormat('dd/MM').format(d.day),
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
