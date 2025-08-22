// lib/data/db/app_database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_sqflite/drift_sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    Workouts,
    WorkoutExercises,
    SetEntries,
    Templates,
    TemplateExercises,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ↑ aumente sempre que mudar o schema
  @override
  int get schemaVersion => 2;

  // -------------------- LOOKUPS --------------------

  Future<Workout?> getWorkoutById(String id) =>
      (select(workouts)..where((w) => w.id.equals(id))).getSingleOrNull();

  Future<Exercise?> getExerciseById(String id) =>
    (select(exercises)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<WorkoutExercise?> getWorkoutExerciseById(String id) =>
      (select(workoutExercises)..where((we) => we.id.equals(id))).getSingleOrNull();

  Future<List<Exercise>> getAllExercises() => select(exercises).get();

  Future<List<Workout>> listWorkoutsDesc() =>
      (select(workouts)..orderBy([(w) => OrderingTerm.desc(w.dateEpoch)])).get();

  /// Só treinos **ativos** (done = false)
  Future<List<Workout>> listActiveWorkoutsDesc() =>
      (select(workouts)
            ..where((w) => w.done.equals(false))
            ..orderBy([(w) => OrderingTerm.desc(w.dateEpoch)]))
          .get();

  Future<List<WorkoutExercise>> listWorkoutExercises(String workoutId) =>
      (select(workoutExercises)
            ..where((we) => we.workoutId.equals(workoutId))
            ..orderBy([(we) => OrderingTerm.asc(we.ord)]))
          .get();

  Future<List<SetEntry>> listSets(String workoutExerciseId) =>
      (select(setEntries)
            ..where((s) => s.workoutExerciseId.equals(workoutExerciseId))
            ..orderBy([(s) => OrderingTerm.asc(s.setIndex)]))
          .get();

  // Templates
  Future<List<Template>> listTemplates() =>
      (select(templates)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Future<Template?> getTemplateById(String id) =>
      (select(templates)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<TemplateExercise>> listTemplateExercises(String templateId) =>
      (select(templateExercises)
            ..where((te) => te.templateId.equals(templateId))
            ..orderBy([(te) => OrderingTerm.asc(te.ord)]))
          .get();

  // -------------------- INSERTS / UPDATES --------------------

  // Exercises
  Future<void> insertExercise(ExercisesCompanion entry) =>
      into(exercises).insert(entry, mode: InsertMode.insertOrReplace);

  // Workouts
  Future<String> createWorkout({
    required String id,
    required DateTime date,
    String? title,
    String? notes,
  }) async {
    await into(workouts).insert(
      WorkoutsCompanion.insert(
        id: id,
        dateEpoch: date.millisecondsSinceEpoch,
        title: Value(title),
        notes: Value(notes),
        done: const Value(false),
      ),
    );
    return id;
  }

  Future<void> setWorkoutDone(String workoutId, bool done) async {
    await (update(workouts)..where((w) => w.id.equals(workoutId)))
        .write(WorkoutsCompanion(done: Value(done)));
  }

  // WorkoutExercises
  Future<String> addExerciseToWorkout({
    required String id,
    required String workoutId,
    required String exerciseId,
    required int ord,
  }) async {
    await into(workoutExercises).insert(
      WorkoutExercisesCompanion.insert(
        id: id,
        workoutId: workoutId,
        exerciseId: exerciseId,
        ord: Value(ord),
        done: const Value(false),
      ),
    );
    return id;
  }

  Future<void> updateWorkoutExerciseOrder({
    required String workoutExerciseId,
    required int ord,
  }) async {
    await (update(workoutExercises)..where((we) => we.id.equals(workoutExerciseId)))
        .write(WorkoutExercisesCompanion(ord: Value(ord)));
  }

  Future<void> setWorkoutExerciseDone({
    required String workoutExerciseId,
    required bool done,
  }) async {
    await (update(workoutExercises)..where((we) => we.id.equals(workoutExerciseId)))
        .write(WorkoutExercisesCompanion(done: Value(done)));
  }

  // Sets
  Future<void> addSet({
    required String id,
    required String workoutExerciseId,
    required int setIndex,
    required int reps,
    required double weight,
    double? rpe,
    int? restSec,
    String? note,
  }) async {
    await into(setEntries).insert(
      SetEntriesCompanion.insert(
        id: id,
        workoutExerciseId: workoutExerciseId,
        setIndex: setIndex,
        reps: reps,
        weight: Value(weight),
        rpe: Value(rpe),
        restSec: Value(restSec),
        note: Value(note),
      ),
    );
  }

  // Templates
  Future<String> createTemplate({
    required String id,
    required String name,
  }) async {
    await into(templates).insert(
      TemplatesCompanion.insert(id: id, name: name),
    );
    return id;
  }

  Future<void> addTemplateExercise({
    required String id,
    required String templateId,
    required String exerciseId,
    required int ord,
  }) async {
    await into(templateExercises).insert(
      TemplateExercisesCompanion.insert(
        id: id,
        templateId: templateId,
        exerciseId: exerciseId,
        ord: Value(ord),
      ),
    );
  }
}

// --------- Conexão com SQLite (mobile via sqflite executor) ---------
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'gym_tracker.sqlite'));
    // sqflite executor (Android/iOS)
    return SqfliteQueryExecutor(path: file.path);
    // Para desktop, você poderia usar:
    // return NativeDatabase.createInBackground(file);
  });
}

// --------- Riverpod Provider do banco ---------
/// Use `ref.read(databaseProvider)` para obter uma instância do banco.
/// Ele é fechado automaticamente quando o provider for descartado.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
