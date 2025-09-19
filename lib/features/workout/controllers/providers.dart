// lib/features/workout/controllers/providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/db/app_database.dart';
import '../../../data/repositories/workout_repository.dart';

/// Provider raiz do banco de dados Drift (SQLite local).
/// Ele é `Provider<AppDatabase>` e gerencia o acesso às tabelas.
final dbProvider = Provider<AppDatabase>((ref) {
  return AppDatabase(); // cria instância do banco
});

/// Provider do repositório principal de Workout/Exercise.
/// Este repositório encapsula a lógica de CRUD no banco.
///
/// -> Usa `dbProvider` internamente.
/// -> É por aqui que você acessa `allExercises`, `createWorkout`, `listActiveWorkouts` etc.
final workoutRepoProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(dbProvider);
  return WorkoutRepository(db);
});

/// Provider usado só na inicialização do app.
/// Ele garante que, ao abrir pela primeira vez, o seed inicial de exercícios será criado.
/// Exemplo: Supino, Agachamento, Remada.
final seedFutureProvider = FutureProvider<void>((ref) async {
  final repo = ref.watch(workoutRepoProvider);
  await repo.ensureSeed(); // cria exercícios base se necessário
});
