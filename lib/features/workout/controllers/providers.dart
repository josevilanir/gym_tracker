import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/db/app_database.dart';
import '../../../data/repositories/workout_repository.dart';

// DB singleton
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// Repo
final workoutRepoProvider = Provider<WorkoutRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return WorkoutRepository(db);
});

// Seed inicial (chamado na TodayPage)
final seedFutureProvider = FutureProvider<void>((ref) async {
  final repo = ref.read(workoutRepoProvider);
  await repo.ensureSeed();
});
