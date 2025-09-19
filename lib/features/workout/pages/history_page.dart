// lib/features/workout/pages/history_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/providers.dart';
import '../../../data/db/app_database.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(workoutRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Histórico')),
      body: FutureBuilder<List<Workout>>(
        future: repo.listWorkouts(),
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
                  const Text('Nenhum treino concluído ainda.'),
                  const SizedBox(height: 8),
                  Text(
                    'Conclua um treino para vê-lo aqui.',
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
            itemBuilder: (context, i) {
              final w = items[i];
              final date =
                  DateTime.fromMillisecondsSinceEpoch(w.dateEpoch);
              final dateStr = DateFormat('dd/MM, HH:mm').format(date);
              final title =
                  (w.title?.trim().isNotEmpty ?? false) ? w.title! : 'Treino sem nome';
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(title),
                  subtitle: Text('Concluído em $dateStr'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
