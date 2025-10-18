// lib/features/workout/controllers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/workout_repository.dart';

final workoutRepoProvider = Provider<WorkoutRepository>((ref) {

  final db = ref.watch(databaseProvider);
  return WorkoutRepository(db);
});

final seedFutureProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(workoutRepoProvider);
  await repo.ensureSeed(); // cria exercícios base se necessário
});