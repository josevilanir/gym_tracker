// lib/features/workout/controllers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/workout_repository.dart';

/// Provider do repositório principal de Workout/Exercise.
/// Este repositório encapsula a lógica de CRUD no banco.
///
/// -> Usa `databaseProvider` (de app_database.dart) internamente.
/// -> É por aqui que você acessa `allExercises`, `createWorkout`, `listActiveWorkouts` etc.
final workoutRepoProvider = Provider<WorkoutRepository>((ref) {
  // ✅ USA O PROVIDER DO app_database.dart (que fecha o banco corretamente)
  final db = ref.watch(databaseProvider);
  return WorkoutRepository(db);
});

/// Provider usado só na inicialização do app.
/// Ele garante que, ao abrir pela primeira vez, o seed inicial de exercícios será criado.
/// Exemplo: Supino, Agachamento, Remada.
final seedFutureProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(workoutRepoProvider);
  await repo.ensureSeed(); // cria exercícios base se necessário
});